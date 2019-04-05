//
//  HTTPService.swift
//  Lumos
//
//  Created by Christoph Pageler on 09.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import Alamofire
import UIKit


class HTTPService {

    static let shared = HTTPService()

    private var baseURL: String?

    private let sessionManagerDefault: Alamofire.SessionManager
    private let sessionManagerSmallTimeout: Alamofire.SessionManager

    public private(set) var imageUploads: [ImageUpload] = []

    public static let didUpdateUploadsNotification = Notification.Name("didUpdateUploadsNotification")

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        self.sessionManagerSmallTimeout = Alamofire.SessionManager(configuration: config,
                                                                   serverTrustPolicyManager: nil)
        self.sessionManagerDefault = Alamofire.SessionManager()
    }

    public var nameForPhotos: String? {
        get {
            guard let username = UserDefaults.standard.string(forKey: "usernameForPhotos") else {
                return UIDevice.current.name
            }
            return username
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "usernameForPhotos")
            UserDefaults.standard.synchronize()
        }
    }

    public func hasValidServerConfiguration(completion: @escaping ((Bool) -> Void)) {
        guard let address = UserDefaults.standard.string(forKey: "address"),
            let port = UserDefaults.standard.object(forKey: "port") as? Int
        else {
            completion(false)
            return
        }
        testConnection(address: address, port: port) { success in
            self.baseURL = self.baseURLFrom(address: address, port: port)
            completion(success)
        }
    }

    public func prepareForServer(at address: String,
                                 port: Int,
                                 name: String,
                                 completion: @escaping ((Bool) -> Void)) {
        testConnection(address: address, port: port) { success in
            if success {
                UserDefaults.standard.set(address, forKey: "address")
                UserDefaults.standard.set(port, forKey: "port")
                UserDefaults.standard.set(name, forKey: "serverName")
                UserDefaults.standard.synchronize()
                self.baseURL = self.baseURLFrom(address: address, port: port)
            }
            completion(success)
        }

    }

    private func testConnection(address: String, port: Int, completion: @escaping ((Bool) -> Void)) {
        let baseURL = baseURLFrom(address: address, port: port)
        sessionManagerSmallTimeout.request(baseURL + "/api/v1/test",
                                           method: .get,
                                           parameters: nil,
                                           encoding: URLEncoding.default,
                                           headers: nil).responseJSON
        { response in
            switch response.result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }

    private func baseURLFrom(address: String, port: Int) -> String {
        return "http://\(address):\(port)"
    }

    public func getAllImages(completion: @escaping (([ImageDTO]?) -> Void)) {
        guard let baseURL = baseURL else {
            completion(nil)
            return
        }
        sessionManagerDefault.request(baseURL + "/api/v1/images",
                                      method: .get,
                                      parameters: nil,
                                      encoding: URLEncoding.default,
                                      headers: nil).responseJSON
        { response in
            switch response.result {
            case .success(let data):
                if let json = data as? [String: Any] {
                    if let success = json["success"] as? Bool, success == true {
                        completion(ImageDTO.imagesFrom(json))
                    } else {
                        completion(nil)
                    }
                } else {
                }
            case .failure:
                completion(nil)
            }
        }
    }

    public func uploadImage(_ image: UIImage, completion: ((Bool) -> Void)?) {
        guard let baseURL = baseURL else {
            completion?(false)
            return
        }

        let upload = ImageUpload(image: image, status: .uploading)
        imageUploads.append(upload)
        sendDidUpdateUploadsNotification()

        guard let imageData = image.jpegData(compressionQuality: 1) else {
            completion?(false)
            return
        }
        let base64ImageString = imageData.base64EncodedString()

        sessionManagerDefault.request(baseURL + "/api/v1/images/upload",
                                      method: .post,
                                      parameters: [
                                        "uuid": UUID().uuidString,
                                        "name": nameForPhotos ?? "",
                                        "image": base64ImageString
                                      ],
                                      encoding: JSONEncoding.default,
                                      headers: nil)
        .responseJSON { response in
            switch response.result {
            case .success:
                if let index = self.imageUploads.firstIndex(of: upload) {
                    self.imageUploads.remove(at: index)
                }
            case .failure:
                upload.status = .failed
            }
            completion?(response.result.isSuccess)
            self.sendDidUpdateUploadsNotification()
        }
    }

    public func retryFailedUploads() {
        var retryUploads: [ImageUpload] = []
        let failed = imageUploads.filter({ $0.status == .failed })
        for upload in failed {
            if let index = imageUploads.firstIndex(of: upload) {
                imageUploads.remove(at: index)
                retryUploads.append(upload)
            }
        }

        for retry in retryUploads {
            uploadImage(retry.image, completion: nil)
        }
    }

    private func sendDidUpdateUploadsNotification() {
        NotificationCenter.default.post(name: HTTPService.didUpdateUploadsNotification,
                                        object: nil)
    }

}


public class ImageUpload: Equatable, Hashable {

    public enum Status: Int {
        case uploading
        case failed
    }

    public let image: UIImage
    public var status: Status

    public init(image: UIImage, status: Status) {
        self.image = image
        self.status = status
    }

    public static func == (lhs: ImageUpload, rhs: ImageUpload) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(status)
    }

}

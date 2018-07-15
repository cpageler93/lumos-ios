//
//  HTTPService.swift
//  23Angle
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

    private init() {
        
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

    public func prepareForServer(at address: String, port: Int, completion: @escaping ((Bool) -> Void)) {
        testConnection(address: address, port: port) { success in
            if success {
                UserDefaults.standard.set(address, forKey: "address")
                UserDefaults.standard.set(port, forKey: "port")
                UserDefaults.standard.synchronize()
                self.baseURL = self.baseURLFrom(address: address, port: port)
            }
            completion(success)
        }

    }

    private func testConnection(address: String, port: Int, completion: @escaping ((Bool) -> Void)) {
        let baseURL = baseURLFrom(address: address, port: port)
        Alamofire.request(baseURL + "/api/v1/test",
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
        Alamofire.request(baseURL + "/api/v1/images",
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

    public func uploadImage(_ image: UIImage, completion: @escaping ((Bool) -> Void)) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        guard let imageData = UIImageJPEGRepresentation(image, 1) else {
            completion(false)
            return
        }
        let base64ImageString = imageData.base64EncodedString()

        Alamofire.request(baseURL + "/api/v1/images/upload",
                          method: .post,
                          parameters: [
                            "uuid": UUID().uuidString,
                            "name": nameForPhotos ?? "",
                            "image": base64ImageString
                          ],
                          encoding: JSONEncoding.default,
                          headers: nil).responseJSON
        { response in
            print("response: \(response)")
        }
    }

}

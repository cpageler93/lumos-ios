//
//  ImageDTO.swift
//  23Angle
//
//  Created by Christoph Pageler on 10.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation


class ImageDTO {

    var uuid: String
    var filename: String
    var uploadedFrom: String
    var totalViewCount: Int
    var show: Bool
    var createdDate: Date
    var data: String?

    init(uuid: String,
         filename: String,
         uploadedFrom: String,
         totalViewCount: Int,
         show: Bool,
         createdDate: Date,
         data: String?) {
        self.uuid = uuid
        self.filename = filename
        self.uploadedFrom = uploadedFrom
        self.totalViewCount = totalViewCount
        self.show = show
        self.createdDate = createdDate
        self.data = data
    }

    static func imagesFrom(_ dict: [String: Any]) -> [ImageDTO]? {
        guard let jsonImages = dict["images"] as? [[String: Any]] else { return nil }
        return jsonImages.compactMap { jsonImage in
            guard let uuid = jsonImage["uuid"] as? String,
                let filename = jsonImage["filename"] as? String,
                let uploadedFrom = jsonImage["uploadedFrom"] as? String,
                let totalViewCount = jsonImage["totalViewCount"] as? Int,
                let show = jsonImage["show"] as? Bool,
                let createdDateString = jsonImage["createdDate"] as? String,
                let createdDate = ISO8601DateFormatter().date(from: createdDateString)
            else {
                return nil
            }
            let data = jsonImage["data"] as? String
            return ImageDTO(uuid: uuid, 
                            filename: filename,
                            uploadedFrom: uploadedFrom,
                            totalViewCount: totalViewCount,
                            show: show,
                            createdDate: createdDate,
                            data: data)
        }
    }

}

//
//  LightroomAsset.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 03.01.26.
//

import Foundation

class LightroomAsset : Hashable, SourcePhoto {
    enum AssetType {
        case other
        case image
    }
    
    let id: String
    let captureDate: Date?
    let lastModifiedDate: Date?
    let fileName: String?

    var album: LightroomAlbum?

    init(id: String, captureDate: Date?, lastModifiedDate: Date?, fileName: String?) {
        self.id = id
        self.captureDate = captureDate
        self.lastModifiedDate = lastModifiedDate
        self.fileName = fileName
    }
    
    public static func == (lhs: LightroomAsset, rhs: LightroomAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LightroomAsset {
    static func instance(from json: [String: Any]) -> LightroomAsset? {
        if let assetId = json["id"] as? String {
            if let payload = json["payload"] as? [String: Any], let subtype = json["subtype"] as? String {
                if subtype == "image" {
//                    print("---- Asset:")
//                    print(json)

                    var captureDate: Date?
                    if let captureDateString = payload["captureDate"] as? String, captureDateString.count >= 19 {
                        let clippedCaptureDateString = captureDateString.prefix(19)
                        captureDate = try? Date("\(clippedCaptureDateString)Z", strategy: .iso8601)
                    }
                    else {
                        captureDate = nil
                    }
                    
                    let fileName: String?
                    if let importSource = payload["importSource"] as? [String: Any] {
                        fileName = importSource["fileName"] as? String
                    }
                    else {
                        fileName = nil
                    }
                    
                    var lastModifiedDate: Date?
                    
                    if let lastModifiedDateString = json["updated"] as? String {
                        lastModifiedDate = try? Date(lastModifiedDateString, strategy: .iso8601)
                    }                    
                    
                    return LightroomAsset(id: assetId, captureDate: captureDate, lastModifiedDate: lastModifiedDate, fileName: fileName)
                }
            }
        }

        return nil
    }
    
    static func list(from json: [[String: Any]]) -> [LightroomAsset] {
        var list: [LightroomAsset] = []
        
        for item in json {
            if let asset = LightroomAsset.instance(from: item) {
                list.append(asset)
            }
        }
        
        return list
    }
}

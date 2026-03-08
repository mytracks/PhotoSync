//
//  Asset.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 03.01.26.
//

import Foundation

class Asset : Hashable, SourcePhoto {
    enum AssetType {
        case other
        case image
    }
    
    let id: String
    let captureDate: Date?
    let fileName: String?

    var album: Album?

    init(id: String, captureDate: Date?, fileName: String?) {
        self.id = id
        self.captureDate = captureDate
        self.fileName = fileName
    }
    
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Asset {
    static func instance(from json: [String: Any]) -> Asset? {
        if let assetId = json["id"] as? String {
            if let payload = json["payload"] as? [String: Any] {
//                print("---- Asset:")
//                print(json)
                    
                let captureDate: Date?
                if let captureDateString = payload["captureDate"] as? String {
                    captureDate = try? Date(captureDateString, strategy: .iso8601)
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

                return Asset(id: assetId, captureDate: captureDate, fileName: fileName)
            }
        }

        return nil
    }
    
    static func list(from json: [[String: Any]]) -> [Asset] {
        var list: [Asset] = []
        
        for item in json {
            if let asset = Asset.instance(from: item) {
                list.append(asset)
            }
        }
        
        return list
    }
}

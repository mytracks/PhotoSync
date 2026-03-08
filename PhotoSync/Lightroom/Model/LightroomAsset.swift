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
    let fileName: String?

    var album: LightroomAlbum?

    init(id: String, captureDate: Date?, fileName: String?) {
        self.id = id
        self.captureDate = captureDate
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
            if let payload = json["payload"] as? [String: Any] {
                print("---- Asset:")
                print(json)
                    
                var captureDate: Date?
                if let captureDateString = payload["captureDate"] as? String {
                    captureDate = try? Date(captureDateString, strategy: .iso8601)
                    if captureDate == nil, captureDateString.count == 19 {
                        captureDate = try? Date("\(captureDateString)Z", strategy: .iso8601)
                    }
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

                return LightroomAsset(id: assetId, captureDate: captureDate, fileName: fileName)
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

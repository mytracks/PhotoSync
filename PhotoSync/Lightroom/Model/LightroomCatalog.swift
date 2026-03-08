//
//  LightroomCatalog.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 31.12.25.
//

import Foundation

class LightroomCatalog : Hashable {
    let id: String
    let subtype: String
    let name: String
    
    init(id: String, subtype: String, name: String) {
        self.id = id
        self.subtype = subtype
        self.name = name
    }

    public static func == (lhs: LightroomCatalog, rhs: LightroomCatalog) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LightroomCatalog {
    static func from(json: [String: Any]) -> LightroomCatalog? {
        if let id = json["id"] as? String, let subtype = json["subtype"] as? String {
            if let payload = json["payload"] as? [String: Any], let name = payload["name"] as? String {
                return LightroomCatalog(id: id, subtype: subtype, name: name)
            }
        }
        
        return nil
    }
}

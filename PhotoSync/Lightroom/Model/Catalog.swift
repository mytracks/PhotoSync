//
//  Catalog.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 31.12.25.
//

import Foundation

class Catalog : Hashable {
    let id: String
    let subtype: String
    let name: String
    
    init(id: String, subtype: String, name: String) {
        self.id = id
        self.subtype = subtype
        self.name = name
    }

    public static func == (lhs: Catalog, rhs: Catalog) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Catalog {
    static func from(json: [String: Any]) -> Catalog? {
        if let id = json["id"] as? String, let subtype = json["subtype"] as? String {
            if let payload = json["payload"] as? [String: Any], let name = payload["name"] as? String {
                return Catalog(id: id, subtype: subtype, name: name)
            }
        }
        
        return nil
    }
}

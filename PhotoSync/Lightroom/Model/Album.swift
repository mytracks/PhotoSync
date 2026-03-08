//
//  Album.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 31.12.25.
//

import Foundation

class Album : Hashable, Identifiable, SourceFolder {
    enum AlbumType {
        case other
        case topic
        case album
        case folder
        case smart
    }
    
    let id: String
    let name: String
    let subtype: String
    let parentId: String?
    
    var parent: Album?
    var subAlbums: [Album] = []

    init(id: String, name: String, subtype: String, parentId: String?) {
        self.id = id
        self.name = name
        self.subtype = subtype
        self.parentId = parentId
    }
    
    public static func == (lhs: Album, rhs: Album) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var type: AlbumType {
        switch subtype {
        case "collection":
            return .album
        case "collection_set":
            return .folder
        case "smart":
            return .smart
        case "topic":
            return .topic
        default:
            return .other
        }
    }
}

extension Album {
    static func instance(from json: [String: Any]) -> Album? {
        if let id = json["id"] as? String, let subtype = json["subtype"] as? String {
            if let payload = json["payload"] as? [String: Any] {
                if let name = payload["name"] as? String {
                    let parentId: String?
                    if let parent = payload["parent"] as? [String: Any] {
                        parentId = parent["id"] as? String
                    }
                    else {
                        parentId = nil
                    }
                    
//                    print("Subtype: \(name) \(subtype)")
                    
                    return Album(id: id, name: name, subtype: subtype, parentId: parentId)
                }
            }
        }

        return nil
    }
    
    static func list(from json: [[String: Any]]) -> [Album] {
        var list: [Album] = []
        
        for item in json {
            if let album = Album.instance(from: item) {
                list.append(album)
            }
        }
        
        return list
    }
}

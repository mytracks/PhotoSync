//
//  Asset.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 03.01.26.
//

class AlbumAsset : Hashable {
    let id: String
    let albumId: String?
    let albumAssetId: String?

    var album: Album?

    init(id: String, albumId: String, albumAssetId: String) {
        self.id = id
        self.albumId = albumId
        self.albumAssetId = albumAssetId
    }
    
    public static func == (lhs: AlbumAsset, rhs: AlbumAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension AlbumAsset {
    static func instance(from json: [String: Any], albumId: String) -> AlbumAsset? {
        if let albumAssetId = json["id"] as? String {
            if let asset = json["asset"] as? [String: Any] {
                if let assetId = asset["id"] as? String {
//                    print("---- AlbumAsset:")
//                    print(json)
                    
                    return AlbumAsset(id: assetId, albumId: albumId, albumAssetId: albumAssetId)
                }
            }
        }

        return nil
    }
    
    static func list(from json: [[String: Any]], albumId: String) -> [AlbumAsset] {
        var list: [AlbumAsset] = []
        
        for item in json {
            if let albumAsset = AlbumAsset.instance(from: item, albumId: albumId) {
                list.append(albumAsset)
            }
        }
        
        return list
    }
}

//
//  LightroomAlbumAsset.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 03.01.26.
//

class LightroomAlbumAsset : Hashable {
    let id: String
    let albumId: String?
    let albumAssetId: String?

    var album: LightroomAlbum?

    init(id: String, albumId: String, albumAssetId: String) {
        self.id = id
        self.albumId = albumId
        self.albumAssetId = albumAssetId
    }
    
    public static func == (lhs: LightroomAlbumAsset, rhs: LightroomAlbumAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LightroomAlbumAsset {
    static func instance(from json: [String: Any], albumId: String) -> LightroomAlbumAsset? {
        if let albumAssetId = json["id"] as? String {
            if let asset = json["asset"] as? [String: Any] {
                if let assetId = asset["id"] as? String {
//                    print("---- AlbumAsset:")
//                    print(json)
                    
                    return LightroomAlbumAsset(id: assetId, albumId: albumId, albumAssetId: albumAssetId)
                }
            }
        }

        return nil
    }
    
    static func list(from json: [[String: Any]], albumId: String) -> [LightroomAlbumAsset] {
        var list: [LightroomAlbumAsset] = []
        
        for item in json {
            if let albumAsset = LightroomAlbumAsset.instance(from: item, albumId: albumId) {
                list.append(albumAsset)
            }
        }
        
        return list
    }
}

//
//  LightroomConnector.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 31.12.25.
//

import Foundation

enum LightroomConnectorError: Error {
    case general(String)
}

@MainActor
@Observable
class LightroomConnector {
    public private(set) var lightroomCatalog: Catalog?
    private var albumDict = [String : Album]()
    public private(set) var rootAlbums: [Album] = []

    public private(set) var albumAssetsDict = [String : [AlbumAsset]]()
    public private(set) var assetsDict = [String : Asset]()
    
    public private(set) var albums = [Album]()
    
    public func loadAlbums(authManager: AdobeAuthManager) async {
        guard let accessToken = authManager.accessToken else { return }
        await loadCatalog(authManager: authManager)        
        guard let lightroomCatalog else { return }
        guard self.rootAlbums.isEmpty else { return }

        let client = LightroomAPIClient(accessToken: accessToken)
        
        if let albums = try? await client.getAlbums(catalogId: lightroomCatalog.id) {
            self.albumDict = albums.reduce(into: [String : Album]()) { dict, album in
//                if album.subtype
                dict[album.id] = album
            }
            
            self.albums = Array(self.albumDict.values)
            
            self.createAlbumHierarchy()
        }
    }
    
    public func getAlbumAssets(authManager: AdobeAuthManager, album: Album) async -> [AlbumAsset] {
        guard let accessToken = authManager.accessToken else { return [] }
        await loadCatalog(authManager: authManager)
        guard let lightroomCatalog else { return [] }

        if self.albumAssetsDict[album.id] == nil {            
            let client = LightroomAPIClient(accessToken: accessToken)
            
            if let assets = try? await client.getAlbumAssets(catalogId: lightroomCatalog.id, albumId: album.id) {
                self.albumAssetsDict[album.id] = assets
            }
        }
        
        return self.albumAssetsDict[album.id] ?? []
    }
    
    public func getAssets(authManager: AdobeAuthManager, assetIds: [String]) async -> [Asset] {
        guard let accessToken = authManager.accessToken else { return [] }
        await loadCatalog(authManager: authManager)
        guard let lightroomCatalog else { return [] }
        
        let assetIdsToLoad = assetIds.filter({self.assetsDict[$0] == nil})

        let client = LightroomAPIClient(accessToken: accessToken)
        
        if let assets = try? await client.getAssets(catalogId: lightroomCatalog.id, assetIds: assetIdsToLoad) {
            for asset in assets {
                self.assetsDict[asset.id] = asset
            }
        }
        
        return assetIds.compactMap({self.assetsDict[$0]})
    }
    
    public func getAssets(authManager: AdobeAuthManager, album: Album) async -> [Asset] {
        let albumAssets = await self.getAlbumAssets(authManager: authManager, album: album)
        let assets = await self.getAssets(authManager: authManager, assetIds: albumAssets.map(\.id))
        return assets
    }
    
    private func loadCatalog(authManager: AdobeAuthManager) async {
        guard self.lightroomCatalog == nil else { return }
        guard let accessToken = authManager.accessToken else { return }
        
        let client = LightroomAPIClient(accessToken: accessToken)
        
        if let catalog = try? await client.getCatalog() {
            if catalog.subtype == "lightroom" {
                self.lightroomCatalog = catalog
            }
        }
    }
    
    private func createAlbumHierarchy() {
        for album in self.albums {
            if let parentId = album.parentId {
                if let parent = self.albumDict[parentId] {
                    album.parent = parent
                    parent.subAlbums.append(album)
                }
            }
        }
        
        self.rootAlbums = self.albums.filter({ $0.parentId == nil })
    }
    
    public func generateFullsizeRendition(authManager: AdobeAuthManager, asset: Asset) async throws {
        guard let accessToken = authManager.accessToken else { return }
        guard let lightroomCatalog else { return }

        let client = LightroomAPIClient(accessToken: accessToken)
        
        try await client.generateFullsizeRenditions(catalogId: lightroomCatalog.id, assetId: asset.id)
    }
    
    public func getFullsizeRendition(authManager: AdobeAuthManager, asset: Asset) async throws -> Data {
        guard let accessToken = authManager.accessToken else { throw LightroomConnectorError.general("no access token") }
        guard let lightroomCatalog else { throw LightroomConnectorError.general("no catalog") }

        let client = LightroomAPIClient(accessToken: accessToken)
        
        return try await client.getFullsizeRendition(catalogId: lightroomCatalog.id, assetId: asset.id)
    }
}


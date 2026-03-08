//
//  LightroomSourceProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 05.03.26.
//

import Foundation

class LightroomSourceConfiguration : SourceConfiguration {
    var rootAlbum: Album
    
    init(rootAlbum: Album) {
        self.rootAlbum = rootAlbum
    }
}

@MainActor
@Observable
class LightroomSourceProvider : SourceProvider {
    private let authManager: AdobeAuthManager
    private let lightroomConnector: LightroomConnector
    
    var albums: [Album]?
    
    init(authManager: AdobeAuthManager, lightroomConnector: LightroomConnector) {
        self.authManager = authManager
        self.lightroomConnector = lightroomConnector
        self.observeState()
    }
    
    func observeState() {
        withObservationTracking {
            if self.authManager.isAuthorized {
                self.loadAlbums()
            }
        } onChange: {
            Task { @MainActor in
                self.observeState()
            }
        }
    }
    
    private func loadAlbums() {
        guard self.authManager.isAuthorized else { return }
        guard self.albums == nil else { return }
        
        Task {
            await self.lightroomConnector.loadAlbums(authManager: self.authManager)
            self.albums = self.lightroomConnector.albums.filter({$0.type == .album}).sorted(by: { $0.name < $1.name })
        }
    }
    
    func getRootFolder(for config: LightroomSourceConfiguration) async throws -> any SourceFolder {
        config.rootAlbum
    }
    
    func getSubfolders(folder: SourceFolder, configuration: Configuration) async throws -> [SourceFolder] {
        if let folder = folder as? Album {
            return folder.subAlbums
        }
        
        return []
    }
    
    func getPhotos(folder: SourceFolder, configuration: Configuration) async throws -> [SourcePhoto] {
        if let album = folder as? Album {
            return await self.lightroomConnector.getAssets(authManager: self.authManager, album: album)
        }
        
        return []
    }
    
    func getFilename(photo: SourcePhoto, configuration: Configuration) async throws -> String? {
        if let asset = photo as? Asset {
            return asset.fileName
        }
        
        return nil
    }
    
    func getCaptureDate(photo: SourcePhoto, configuration: Configuration) async throws -> Date? {
        if let asset = photo as? Asset {
            return asset.captureDate
        }
        
        return nil
    }
    
    func requestJpegData(photo: SourcePhoto, configuration: Configuration, jpgQuality: CGFloat) async throws {
        if let asset = photo as? Asset {
            try await self.lightroomConnector.generateFullsizeRendition(authManager: self.authManager, asset: asset)
        }
    }
    
    func getJpegData(photo: SourcePhoto, configuration: Configuration, jpgQuality: CGFloat) async throws -> Data? {
        if let asset = photo as? Asset {
            var retries = 60
            repeat {
                do {
                    return try await self.lightroomConnector.getFullsizeRendition(authManager: self.authManager, asset: asset)
                }
                catch {
                    print("Retry: \(retries)")
                    try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                }
                
                retries -= 1
            }
            while retries > 0
        }
        
        return nil
    }
}

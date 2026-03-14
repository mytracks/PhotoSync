//
//  LightroomSourceProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 05.03.26.
//

import Foundation

class LightroomSourceConfiguration : SourceConfiguration {
    let rootFolder: LightroomAlbum?
    let rootAlbum: LightroomAlbum?
    let canSync: Bool

    init(rootFolder: LightroomAlbum?) {
        self.rootFolder = rootFolder
        self.rootAlbum = nil
        self.canSync = true
    }

    init(rootAlbum: LightroomAlbum?) {
        self.rootFolder = nil
        self.rootAlbum = rootAlbum
        self.canSync = true
    }
}

@MainActor
@Observable
class LightroomSourceProvider : SourceProvider {
    enum State {
        case unintialized
        case loadingAlbums
        case ready
    }
    
    private let authManager: AdobeAuthManager
    private let lightroomConnector: LightroomConnector
    
    var state: State = .unintialized
    
    var albums: [LightroomAlbum]?
    var folders: [LightroomAlbum]?
    
    init(authManager: AdobeAuthManager, lightroomConnector: LightroomConnector) {
        self.authManager = authManager
        self.lightroomConnector = lightroomConnector
        self.observeState()
    }
    
    func observeState() {
        withObservationTracking {
            if self.authManager.isAuthorized {
                if self.state != .ready {
                    self.state = .loadingAlbums
                    self.loadAlbums()
                }
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
            self.folders = self.lightroomConnector.albums.filter({$0.type == .folder}).sorted(by: { $0.name < $1.name })
            
            self.state = .ready
        }
    }
    
    func getRootFolder(for config: any SourceConfiguration) async throws -> (any SourceFolder)? {
        guard let config = config as? LightroomSourceConfiguration else {
            fatalError("Unexpected configuration type")
        }
        
        return config.rootFolder
    }
    
    func getRootAlbum(for config: any SourceConfiguration) async throws -> (any SourceAlbum)? {
        guard let config = config as? LightroomSourceConfiguration else {
            fatalError("Unexpected configuration type")
        }
        
        return config.rootAlbum
    }
    
    func getSubfolders(folder: any SourceFolder, configuration: any SourceConfiguration) async throws -> [any SourceFolder] {
        guard let folder = folder as? LightroomAlbum else {
            fatalError("Unexpected folder type")
        }
        
        return folder.subAlbums.filter({$0.type == .folder}).sorted(by: { $0.name < $1.name })
    }
    
    func getAlbums(folder: any SourceFolder, configuration: any SourceConfiguration) async throws -> [any SourceAlbum] {
        guard let folder = folder as? LightroomAlbum else {
            fatalError("Unexpected folder type")
        }

        return folder.subAlbums.filter({$0.type == .album}).sorted(by: { $0.name < $1.name })
    }

    func getPhotos(album: any SourceAlbum, configuration: any SourceConfiguration) async throws -> [any SourcePhoto] {
        guard let album = album as? LightroomAlbum else {
            fatalError("Unexpected album type")
        }
        
        return await self.lightroomConnector.getAssets(authManager: self.authManager, album: album)
    }
    
    func getFilename(photo: any SourcePhoto, configuration: any SourceConfiguration) async throws -> String? {
        guard let photo = photo as? LightroomAsset else {
            fatalError("Unexpected photo type")
        }
        
        return photo.fileName
    }
    
    func getCaptureDate(photo: any SourcePhoto, configuration: any SourceConfiguration) async throws -> Date? {
        guard let photo = photo as? LightroomAsset else {
            fatalError("Unexpected photo type")
        }

        return photo.captureDate
    }
    
    func requestJpegData(photo: any SourcePhoto, configuration: any SourceConfiguration, jpgQuality: CGFloat) async throws {
        guard let photo = photo as? LightroomAsset else {
            fatalError("Unexpected photo type")
        }

        try await self.lightroomConnector.generateFullsizeRendition(authManager: self.authManager, asset: photo)
    }
    
    func getJpegData(photo: any SourcePhoto, configuration: any SourceConfiguration, jpgQuality: CGFloat) async throws -> Data? {
        guard let photo = photo as? LightroomAsset else {
            fatalError("Unexpected photo type")
        }

        var retries = 60
        repeat {
            do {
                return try await self.lightroomConnector.getFullsizeRendition(authManager: self.authManager, asset: photo)
            }
            catch {
                print("Retry: \(retries)")
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            }
            
            retries -= 1
        }
        while retries > 0
        
        return nil
    }
}

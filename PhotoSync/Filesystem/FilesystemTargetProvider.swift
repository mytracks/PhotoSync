//
//  FilesystemTargetProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 07.03.26.
//

import Foundation

class FilesystemTargetConfiguration: TargetConfiguration {
    let rootFolder: URL?
    let rootAlbum: URL?
    let canSync: Bool
    
    init(rootFolder: URL?) {
        self.rootFolder = rootFolder
        self.rootAlbum = nil
        self.canSync = true
    }

    init(rootAlbum: URL?) {
        self.rootFolder = nil
        self.rootAlbum = rootAlbum
        self.canSync = true
    }
}

class FilesystemTargetFolder: TargetFolder {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}

class FilesystemTargetAlbum: TargetAlbum {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}

class FilesystemTargetPhoto: TargetPhoto {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}

@MainActor
@Observable
class FilesystemTargetProvider : TargetProvider {
    func syncWillStart(config: any TargetConfiguration) {
        guard let config = config as? FilesystemTargetConfiguration else {
            fatalError("Unexpected configuration type")
        }

        if let folderURL = config.rootFolder {
            _ = folderURL.startAccessingSecurityScopedResource()
        }
    }
    
    func syncDidFinish(config: any TargetConfiguration) {
        guard let config = config as? FilesystemTargetConfiguration else {
            fatalError("Unexpected configuration type")
        }

        if let folderURL = config.rootFolder {
            folderURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func getRootFolder(for configuration: any TargetConfiguration) async throws -> (any TargetFolder)? {
        guard let configuration = configuration as? FilesystemTargetConfiguration else {
            fatalError("Unexpected configuration type")
        }
        
        if let url = configuration.rootFolder {
            return FilesystemTargetFolder(url: url)
        }
        
        return nil
    }
    
    func getRootAlbum(for configuration: any TargetConfiguration) async throws -> (any TargetAlbum)? {
        guard let configuration = configuration as? FilesystemTargetConfiguration else {
            fatalError("Unexpected configuration type")
        }
        
        if let url = configuration.rootAlbum {
            return FilesystemTargetAlbum(url: url)
        }
        
        return nil
    }
    
    func fileExists(fileName: String, album: any TargetAlbum, configuration: any TargetConfiguration) async throws -> Bool {
        guard let album = album as? FilesystemTargetAlbum else {
            fatalError("Unexpected album type")
        }
        
        let filepath = album.url.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: filepath.path)
    }
    
    func getLastModifiedDate(fileName: String, album: any TargetAlbum, configuration: any TargetConfiguration) async throws -> Date? {
        guard let album = album as? FilesystemTargetAlbum else {
            fatalError("Unexpected album type")
        }
        
        let filepath = album.url.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: filepath.path) {
            let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey]
            let values = try filepath.resourceValues(forKeys: resourceKeys)
            return values.contentModificationDate
        }
        
        return nil
    }
    
    
    func save(data: Data, fileName: String, album: any TargetAlbum, configuration: any TargetConfiguration) async throws {
        guard let album = album as? FilesystemTargetAlbum else {
            fatalError("Unexpected album type")
        }

        let filepath = album.url.appendingPathComponent(fileName)
        
        FileManager.default.createFile(atPath: filepath.path, contents: data)
    }
    
    func getOrCreateFolder(name: String, baseFolder: (any TargetFolder)?, configuration: any TargetConfiguration) async throws -> any TargetFolder {
        guard let configuration = configuration as? FilesystemTargetConfiguration else {
            fatalError("Unexpected configuration type")
        }
        let baseFolder = baseFolder as? FilesystemTargetFolder
        
        guard let baseURL = baseFolder?.url ?? configuration.rootFolder else {
            throw FilesystemTargetProviderError.general("no base folder")
        }
        
        let folderURL = baseURL.appendingPathComponent(name)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return FilesystemTargetFolder(url: folderURL)
    }
    
    func getOrCreateAlbum(name: String, baseFolder: any TargetFolder, configuration: any TargetConfiguration) async throws -> any TargetAlbum {
        guard let baseFolder = baseFolder as? FilesystemTargetFolder else {
            fatalError("Unexpected base folder type")
        }
        
        let albumURL = baseFolder.url.appendingPathComponent(name)
        
        if !FileManager.default.fileExists(atPath: albumURL.path) {
            try FileManager.default.createDirectory(at: albumURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return FilesystemTargetAlbum(url: albumURL)
    }
}

enum FilesystemTargetProviderError: Error {
    case general(String)
}


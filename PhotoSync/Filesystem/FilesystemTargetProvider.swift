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

    init(rootFolder: URL) {
        self.rootFolder = rootFolder
        self.rootAlbum = nil
    }
    
    init (rootAlbum: URL) {
        self.rootFolder = nil
        self.rootAlbum = rootAlbum
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
    typealias Configuration = FilesystemTargetConfiguration
    
    func getRootFolder(for config: Configuration) async throws -> TargetFolder? {
        if let url = config.rootFolder {
            return FilesystemTargetFolder(url: url)
        }
        
        return nil
    }
    
    func getRootAlbum(for config: Configuration) async throws -> TargetAlbum? {
        if let url = config.rootAlbum {
            return FilesystemTargetAlbum(url: url)
        }
        
        return nil
    }
    
    func fileExists(fileName: String, album: TargetAlbum, configuration: Configuration) async throws -> Bool {
        guard let album = album as? FilesystemTargetAlbum else {
            fatalError("unexpected album type")
        }
        
        let filepath = album.url.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: filepath.path)
    }
    
    func save(data: Data, fileName: String, album: TargetAlbum, configuration: Configuration) async throws {
        guard let album = album as? FilesystemTargetAlbum else {
            fatalError("unexpected album type")
        }

        let filepath = album.url.appendingPathComponent(fileName)
        
        FileManager.default.createFile(atPath: filepath.path, contents: data)
    }
    
    func getOrCreateFolder(name: String, baseFolder: TargetFolder?, configuration: Configuration) async throws -> TargetFolder {
        guard let baseURL = (baseFolder as? FilesystemTargetFolder)?.url ?? configuration.rootFolder else {
            throw FilesystemTargetProviderError.general("no base folder")
        }
        
        let folderURL = baseURL.appendingPathComponent(name)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return FilesystemTargetFolder(url: folderURL)
    }
    
    func getOrCreateAlbum(name: String, baseFolder: TargetFolder, configuration: Configuration) async throws -> TargetAlbum {
        guard let baseURL = (baseFolder as? FilesystemTargetFolder)?.url else {
            throw FilesystemTargetProviderError.general("wrong type")
        }
        
        let albumURL = baseURL.appendingPathComponent(name)
        
        if !FileManager.default.fileExists(atPath: albumURL.path) {
            try FileManager.default.createDirectory(at: albumURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return FilesystemTargetAlbum(url: albumURL)
    }
}

enum FilesystemTargetProviderError: Error {
    case general(String)
}

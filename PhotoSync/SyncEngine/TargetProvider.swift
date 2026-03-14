//
//  TargetProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 07.03.26.
//

import Foundation

protocol TargetConfiguration {
    var canSync: Bool { get }
}

protocol TargetAlbum {
}

protocol TargetFolder {
}

protocol TargetPhoto {
}

protocol TargetProvider {
    associatedtype Configuration: TargetConfiguration
    associatedtype Photo: TargetPhoto
    associatedtype Folder: TargetFolder
    associatedtype Album: TargetAlbum
    
    func getRootFolder(for config: Configuration) async throws -> Folder?
    func getRootAlbum(for config: Configuration) async throws -> Album?

    func getOrCreateFolder(name: String, baseFolder: Folder?, configuration: Configuration) async throws -> Folder
    func getOrCreateAlbum(name: String, baseFolder: Folder, configuration: Configuration) async throws -> Album

    func fileExists(fileName: String, album: Album, configuration: Configuration) async throws -> Bool
    func save(data: Data, fileName: String, album: Album, configuration: Configuration) async throws
}

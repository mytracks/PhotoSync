//
//  TargetProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 07.03.26.
//

import Foundation

protocol TargetConfiguration {
}

protocol TargetAlbum {
}

protocol TargetFolder {
}

protocol TargetPhoto {
}

protocol TargetProvider {
    associatedtype Configuration: TargetConfiguration
    
    func getRootFolder(for config: Configuration) async throws -> TargetFolder?
    func getRootAlbum(for config: Configuration) async throws -> TargetAlbum?

    func getOrCreateFolder(name: String, baseFolder: TargetFolder?, configuration: Configuration) async throws -> TargetFolder
    func getOrCreateAlbum(name: String, baseFolder: TargetFolder, configuration: Configuration) async throws -> TargetAlbum

    func fileExists(fileName: String, album: TargetAlbum, configuration: Configuration) async throws -> Bool
    func save(data: Data, fileName: String, album: TargetAlbum, configuration: Configuration) async throws
}

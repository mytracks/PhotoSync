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
    func syncWillStart(config: any TargetConfiguration)
    func syncDidFinish(config: any TargetConfiguration)

    func getRootFolder(for config: any TargetConfiguration) async throws -> (any TargetFolder)?
    func getRootAlbum(for config: any TargetConfiguration) async throws -> (any TargetAlbum)?

    func getOrCreateFolder(name: String, baseFolder: (any TargetFolder)?, configuration: any TargetConfiguration) async throws -> any TargetFolder
    func getOrCreateAlbum(name: String, baseFolder: any TargetFolder, configuration: any TargetConfiguration) async throws -> any TargetAlbum

    func fileExists(fileName: String, album: any TargetAlbum, configuration: any TargetConfiguration) async throws -> Bool
    func save(data: Data, fileName: String, album: any TargetAlbum, configuration: any TargetConfiguration) async throws
}

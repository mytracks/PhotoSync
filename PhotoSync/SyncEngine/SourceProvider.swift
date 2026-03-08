//
//  SourceProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 06.03.26.
//

import Foundation

protocol SourceConfiguration {
}

protocol SourceAlbum {
    var name: String { get }
}

protocol SourceFolder {
    var name: String { get }
}

protocol SourcePhoto {
}

protocol SourceProvider {
    associatedtype Configuration: SourceConfiguration
    
    func getRootFolder(for config: Configuration) async throws -> SourceFolder?
    func getRootAlbum(for config: Configuration) async throws -> SourceAlbum?

    func getSubfolders(folder: SourceFolder, configuration: Configuration) async throws -> [SourceFolder]
    func getAlbums(folder: SourceFolder, configuration: Configuration) async throws -> [SourceAlbum]
    func getPhotos(album: SourceAlbum, configuration: Configuration) async throws -> [SourcePhoto]
    func getFilename(photo: SourcePhoto, configuration: Configuration) async throws -> String?
    func getCaptureDate(photo: SourcePhoto, configuration: Configuration) async throws -> Date?
    func requestJpegData(photo: SourcePhoto, configuration: Configuration, jpgQuality: CGFloat) async throws
    func getJpegData(photo: SourcePhoto, configuration: Configuration, jpgQuality: CGFloat) async throws -> Data?
}

//
//  SourceProvider.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 06.03.26.
//

import Foundation

protocol SourceConfiguration {
    var canSync: Bool { get }
}

protocol SourceAlbum {
    var name: String { get }
}

protocol SourceFolder {
    var name: String { get }
}

protocol SourcePhoto : Hashable {
}

protocol SourceProvider {
    associatedtype Configuration: SourceConfiguration
    associatedtype Photo: SourcePhoto
    associatedtype Folder: SourceFolder
    associatedtype Album: SourceAlbum

    func getRootFolder(for config: Configuration) async throws -> Folder?
    func getRootAlbum(for config: Configuration) async throws -> Album?

    func getSubfolders(folder: Folder, configuration: Configuration) async throws -> [Folder]
    func getAlbums(folder: Folder, configuration: Configuration) async throws -> [Album]
    func getPhotos(album: Album, configuration: Configuration) async throws -> [Photo]
    func getFilename(photo: Photo, configuration: Configuration) async throws -> String?
    func getCaptureDate(photo: Photo, configuration: Configuration) async throws -> Date?
    func requestJpegData(photo: Photo, configuration: Configuration, jpgQuality: CGFloat) async throws
    func getJpegData(photo: Photo, configuration: Configuration, jpgQuality: CGFloat) async throws -> Data?
}

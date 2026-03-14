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

protocol SourcePhoto {
    var id: String { get }
}

protocol SourceProvider {
    func getRootFolder(for config: any SourceConfiguration) async throws -> (any SourceFolder)?
    func getRootAlbum(for config: any SourceConfiguration) async throws -> (any SourceAlbum)?

    func getSubfolders(folder: any SourceFolder, configuration: any SourceConfiguration) async throws -> [any SourceFolder]
    func getAlbums(folder: any SourceFolder, configuration: any SourceConfiguration) async throws -> [any SourceAlbum]
    func getPhotos(album: any SourceAlbum, configuration: any SourceConfiguration) async throws -> [any SourcePhoto]
    func getFilename(photo: any SourcePhoto, configuration: any SourceConfiguration) async throws -> String?
    func getCaptureDate(photo: any SourcePhoto, configuration: any SourceConfiguration) async throws -> Date?
    func requestJpegData(photo: any SourcePhoto, configuration: any SourceConfiguration, jpgQuality: CGFloat) async throws
    func getJpegData(photo: any SourcePhoto, configuration: any SourceConfiguration, jpgQuality: CGFloat) async throws -> Data?
}

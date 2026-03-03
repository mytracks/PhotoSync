//
//  SyncError.swift
//  PhotoSync
//

import Foundation

enum SyncError: Error, LocalizedError {
    case notAuthorized
    case scanFailed(URL, Error)
    case failedToCreateFolder(String)
    case failedToCreateAlbum(String)
    case failedToAddPhoto(URL, Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Not authorized to access the Photos library."
        case .scanFailed(let url, let err):
            return "Failed to scan \(url.lastPathComponent): \(err.localizedDescription)"
        case .failedToCreateFolder(let name):
            return "Failed to create folder '\(name)'"
        case .failedToCreateAlbum(let name):
            return "Failed to create album '\(name)'"
        case .failedToAddPhoto(let url, let err):
            return "Failed to add \(url.lastPathComponent): \(err.localizedDescription)"
        }
    }
}

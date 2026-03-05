//
//  LightroomSyncError.swift
//  PhotoSync
//

import Foundation

enum LightroomSyncError: Error, LocalizedError {
    case invalidConfiguration
    case folderNotFound
    case invalidResponse
    case noDownloadURL(assetID: String)
    case failedToCreateDirectory(URL, Error)
    case failedToWriteFile(URL, Error)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Please provide API Key, Access Token and Catalog ID."
        case .folderNotFound:
            return "The selected Lightroom folder could not be found."
        case .invalidResponse:
            return "The Lightroom Cloud API returned an unexpected response."
        case .noDownloadURL(let assetID):
            return "No JPG download URL found for asset \(assetID)."
        case .failedToCreateDirectory(let url, let error):
            return "Failed to create folder \(url.path): \(error.localizedDescription)"
        case .failedToWriteFile(let url, let error):
            return "Failed to write \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }
}

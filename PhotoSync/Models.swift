//
//  Models.swift
//  PhotoSync
//

import Foundation

// MARK: - Folder Tree

struct FolderNode {
    let url: URL
    let name: String
    var children: [FolderNode]   // subdirectories
    var photoFiles: [URL]        // image files directly in this folder

    var hasSubfolders: Bool { !self.children.isEmpty }
    var hasPhotos: Bool { !self.photoFiles.isEmpty }

    /// Total number of photos in this node and all descendants
    var totalPhotoCount: Int {
        self.photoFiles.count + self.children.reduce(0) { $0 + $1.totalPhotoCount }
    }
}

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case scanning
    case syncing
    case completed
    case failed(String)

    var isActive: Bool {
        switch self {
        case .scanning, .syncing: return true
        default: return false
        }
    }

    var displayString: String {
        switch self {
        case .idle: return "Ready"
        case .scanning: return "Scanning folder…"
        case .syncing: return "Syncing…"
        case .completed: return "Sync completed"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }
}

// MARK: - Log

struct SyncLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType

    enum LogType {
        case info, success, warning, error
    }
}

// MARK: - Errors

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

//
//  LightroomSyncStatus.swift
//  PhotoSync
//

import Foundation

enum LightroomSyncStatus: Equatable {
    case idle
    case loadingCatalogs
    case loadingFolders
    case scanning
    case syncing
    case completed
    case cancelled
    case failed(String)

    var isActive: Bool {
        switch self {
        case .loadingCatalogs, .loadingFolders, .scanning, .syncing: return true
        default: return false
        }
    }

    var displayString: String {
        switch self {
        case .idle: return "Ready"
        case .loadingCatalogs: return "Loading Lightroom catalogs…"
        case .loadingFolders: return "Loading Lightroom folders…"
        case .scanning: return "Scanning Lightroom source…"
        case .syncing: return "Exporting JPG files…"
        case .completed: return "Sync completed"
        case .cancelled: return "Cancelled"
        case .failed(let message): return "Failed: \(message)"
        }
    }
}

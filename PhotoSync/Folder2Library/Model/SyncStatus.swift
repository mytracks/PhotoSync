//
//  SyncStatus.swift
//  PhotoSync
//

import Foundation

enum SyncStatus: Equatable {
    case idle
    case scanning
    case syncing
    case completed
    case cancelled
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
        case .cancelled: return "Cancelled"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }
}

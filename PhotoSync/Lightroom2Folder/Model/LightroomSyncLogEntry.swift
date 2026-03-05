//
//  LightroomSyncLogEntry.swift
//  PhotoSync
//

import Foundation

struct LightroomSyncLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType

    enum LogType {
        case info
        case success
        case warning
        case error
    }
}

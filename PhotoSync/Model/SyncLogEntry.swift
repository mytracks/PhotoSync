//
//  SyncLogEntry.swift
//  PhotoSync
//

import Foundation

struct SyncLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType

    enum LogType {
        case info, success, warning, error
    }
}

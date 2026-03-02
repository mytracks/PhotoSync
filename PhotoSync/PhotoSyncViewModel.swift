//
//  PhotoSyncViewModel.swift
//  PhotoSync
//

import Foundation
import SwiftUI

@Observable
final class PhotoSyncViewModel {

    // MARK: - State

    var selectedFolderURL: URL?
    var syncStatus: SyncStatus = .idle
    var logEntries: [SyncLogEntry] = []
    var completedPhotos: Int = 0
    var totalPhotos: Int = 0

    var canSync: Bool {
        selectedFolderURL != nil && !syncStatus.isActive
    }

    var progressFraction: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(completedPhotos) / Double(totalPhotos)
    }

    // MARK: - Folder Selection

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the folder you want to sync with your Photos library"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            selectedFolderURL = panel.url
            logEntries = []
            syncStatus = .idle
            completedPhotos = 0
            totalPhotos = 0
        }
    }

    // MARK: - Sync

    func startSync() {
        guard let url = selectedFolderURL else { return }

        Task {
            syncStatus = .scanning
            logEntries = []
            completedPhotos = 0
            totalPhotos = 0

            let service = PhotoLibraryService()
            let engine = SyncEngine(
                photoService: service,
                log: { [weak self] entry in
                    self?.logEntries.append(entry)
                },
                progress: { [weak self] completed, total in
                    self?.completedPhotos = completed
                    self?.totalPhotos = total
                    if self?.syncStatus == .scanning {
                        self?.syncStatus = .syncing
                    }
                }
            )

            do {
                try await engine.run(rootURL: url)
                syncStatus = .completed
                appendLog("Sync finished.", type: .success)
            } catch {
                syncStatus = .failed(error.localizedDescription)
                appendLog("Sync failed: \(error.localizedDescription)", type: .error)
            }
        }
    }

    // MARK: - Helpers

    private func appendLog(_ message: String, type: SyncLogEntry.LogType) {
        logEntries.append(SyncLogEntry(message: message, type: type))
    }
}

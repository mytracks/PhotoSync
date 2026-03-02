//
//  PhotoSyncViewModel.swift
//  PhotoSync
//

import Foundation
import SwiftUI
import Photos

@Observable
final class PhotoSyncViewModel {

    // MARK: - State

    var selectedFolderURL: URL?
    var syncStatus: SyncStatus = .idle
    var logEntries: [SyncLogEntry] = []
    var completedPhotos: Int = 0
    var totalPhotos: Int = 0

    // MARK: - Library Folder State

    /// The Photos library folder (PHCollectionList) to use as the sync root.
    /// When `nil` the library root is used.
    var selectedLibraryFolder: PHCollectionList?

    var selectedLibraryFolderTitle: String? {
        self.selectedLibraryFolder?.localizedTitle
    }

    /// Controls whether the library folder picker sheet is shown.
    var showingLibraryFolderPicker: Bool = false

    /// Top-level PHCollectionList items fetched before showing the picker.
    var availableLibraryFolders: [PHCollectionList] = []

    // MARK: - Derived

    var canSync: Bool {
        self.selectedFolderURL != nil && !self.syncStatus.isActive
    }

    var progressFraction: Double {
        guard self.totalPhotos > 0 else { return 0 }
        return Double(self.completedPhotos) / Double(self.totalPhotos)
    }

    // MARK: - Source Folder Selection

    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the folder you want to sync with your Photos library"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            self.selectedFolderURL = panel.url
            self.logEntries = []
            self.syncStatus = .idle
            self.completedPhotos = 0
            self.totalPhotos = 0
        }
    }

    // MARK: - Library Folder Selection

    /// Requests Photos authorization, fetches available top-level folders
    /// and presents the picker sheet.
    func selectLibraryFolder() {
        Task {
            let service = PhotoLibraryService()
            let authorized = await service.requestAuthorization()
            guard authorized else { return }
            self.availableLibraryFolders = service.fetchTopLevelFolders()
            self.showingLibraryFolderPicker = true
        }
    }

    /// Clears the selected library folder, reverting to the library root.
    func clearLibraryFolder() {
        self.selectedLibraryFolder = nil
    }

    // MARK: - Sync

    private var syncTask: Task<Void, Never>?

    func startSync() {
        guard let url = self.selectedFolderURL else { return }

        let libraryFolder = self.selectedLibraryFolder

        self.syncTask = Task {
            self.syncStatus = .scanning
            self.logEntries = []
            self.completedPhotos = 0
            self.totalPhotos = 0

            if let folderTitle = libraryFolder?.localizedTitle {
                self.appendLog("Target library folder: \(folderTitle)", type: .info)
            } else {
                self.appendLog("Target: Photo Library root", type: .info)
            }

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
                try await engine.run(rootURL: url, baseFolder: libraryFolder)
                self.syncStatus = .completed
                self.appendLog("Sync finished.", type: .success)
            } catch is CancellationError {
                self.syncStatus = .cancelled
                self.appendLog("Sync cancelled.", type: .warning)
            } catch {
                self.syncStatus = .failed(error.localizedDescription)
                self.appendLog("Sync failed: \(error.localizedDescription)", type: .error)
            }
        }
    }

    func cancelSync() {
        self.syncTask?.cancel()
        self.syncTask = nil
    }

    // MARK: - Helpers

    private func appendLog(_ message: String, type: SyncLogEntry.LogType) {
        self.logEntries.append(SyncLogEntry(message: message, type: type))
    }
}

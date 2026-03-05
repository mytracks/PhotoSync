//
//  Lightroom2FolderViewModel.swift
//  PhotoSync
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class Lightroom2FolderViewModel {

    private let clientID = "fdd1936caa144180876858ef4a39b404" // https://developer.adobe.com/console/projects/261591/4566206088344895048/credentials/382583/details
    
    // MARK: - Configuration Input

//    var apiKey: String = ""
    var accessToken: String = ""
    var refreshToken: String = ""

    // MARK: - Catalog Selection

    var selectedCatalogID: String?

    var catalogID: String {
        self.selectedCatalogID ?? ""
    }

    // MARK: - OAuth State

    var oauthStatusMessage: String?
    var isAuthorizing: Bool = false

    // MARK: - Source Selection

    var availableFolders: [LightroomFolder] = []
    var selectedFolderID: String?

    var selectedFolderName: String? {
        guard let selectedFolderID else { return nil }
        return self.availableFolders.first(where: { $0.id == selectedFolderID })?.name
    }

    // MARK: - Target Selection

    var targetFolderURL: URL?

    // MARK: - Sync State

    var syncStatus: LightroomSyncStatus = .idle
    var logEntries: [LightroomSyncLogEntry] = []
    var completedAssets: Int = 0
    var totalAssets: Int = 0

    var progressFraction: Double {
        guard self.totalAssets > 0 else { return 0 }
        return Double(self.completedAssets) / Double(self.totalAssets)
    }

    var canLoadFolders: Bool {
        !self.syncStatus.isActive && self.configuration.isValid
    }

    var canLoadCatalogs: Bool {
        !self.syncStatus.isActive
            && !self.isAuthorizing
            && !self.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canStartOAuth: Bool {
        !self.syncStatus.isActive
            && !self.isAuthorizing
//            && !self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSync: Bool {
        self.configuration.isValid
            && self.selectedFolderID != nil
            && self.targetFolderURL != nil
            && !self.syncStatus.isActive
    }

    private var configuration: LightroomCloudConfiguration {
        LightroomCloudConfiguration(
            apiKey: self.clientID,
            accessToken: self.accessToken,
            catalogID: self.catalogID
        )
    }

    private var syncTask: Task<Void, Never>?
    private let oauthService = AdobeOAuthService()

    // MARK: - Target Folder Picker

    func selectTargetFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the local folder where Lightroom photos should be exported"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            self.targetFolderURL = panel.url
        }
    }

    // MARK: - Source Folder Loading

    func signInWithAdobe() {
        self.syncTask = Task {
            self.isAuthorizing = true
            self.oauthStatusMessage = nil
            self.appendLog("Opening Adobe sign-in…", type: .info)

            do {
                let tokenResponse = try await self.oauthService.signIn(clientID: self.clientID)
                self.accessToken = tokenResponse.accessToken
                self.refreshToken = tokenResponse.refreshToken ?? ""
                self.oauthStatusMessage = "Signed in to Adobe. Access token updated. Loading catalogs…"
                self.appendLog("Adobe sign-in successful.", type: .success)
                try await self.loadCatalogsInternal()
            } catch {
                self.oauthStatusMessage = error.localizedDescription
                self.appendLog("Adobe sign-in failed: \(error.localizedDescription)", type: .error)
            }

            self.isAuthorizing = false
        }
    }

    func loadCatalogs() {
        self.syncTask = Task {
            do {
                try await self.loadCatalogsInternal()
            } catch {
                self.syncStatus = .failed(error.localizedDescription)
                self.oauthStatusMessage = error.localizedDescription
                self.appendLog("Failed to load Lightroom catalogs: \(error.localizedDescription)", type: .error)
            }
        }
    }

    func loadFolders() {
        let configuration = self.configuration

        self.syncTask = Task {
            self.syncStatus = .loadingFolders
            self.logEntries = []
            self.completedAssets = 0
            self.totalAssets = 0

            let service = LightroomCloudService()

            do {
                let folders = try await service.fetchFolders(configuration: configuration)
                    .sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })

                self.availableFolders = folders
                if self.selectedFolderID == nil {
                    self.selectedFolderID = folders.first?.id
                }
                self.syncStatus = .idle
                self.appendLog("Loaded \(folders.count) Lightroom folder(s).", type: .success)
            } catch is CancellationError {
                self.syncStatus = .cancelled
                self.appendLog("Loading folders cancelled.", type: .warning)
            } catch {
                self.syncStatus = .failed(error.localizedDescription)
                self.appendLog("Failed to load Lightroom folders: \(error.localizedDescription)", type: .error)
            }
        }
    }

    // MARK: - Sync

    func startSync() {
        guard let selectedFolderID = self.selectedFolderID,
              let targetFolderURL = self.targetFolderURL else {
            return
        }

        let configuration = self.configuration
        let folders = self.availableFolders

        self.syncTask = Task {
            self.syncStatus = .scanning
            self.logEntries = []
            self.completedAssets = 0
            self.totalAssets = 0

            self.appendLog("Source Lightroom folder: \(self.selectedFolderName ?? selectedFolderID)", type: .info)
            self.appendLog("Target local folder: \(targetFolderURL.path)", type: .info)

            let service = LightroomCloudService()
            let engine = LightroomToFolderSyncEngine(
                service: service,
                log: { [weak self] entry in
                    Task { @MainActor in
                        self?.logEntries.append(entry)
                        if entry.message.hasPrefix("Exporting") {
                            self?.syncStatus = .syncing
                        }
                    }
                },
                progress: { [weak self] completed, total in
                    Task { @MainActor in
                        self?.completedAssets = completed
                        self?.totalAssets = total
                    }
                }
            )

            do {
                try await engine.run(
                    configuration: configuration,
                    selectedFolderID: selectedFolderID,
                    allFolders: folders,
                    targetRootURL: targetFolderURL
                )
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

    private func appendLog(_ message: String, type: LightroomSyncLogEntry.LogType) {
        self.logEntries.append(LightroomSyncLogEntry(message: message, type: type))
    }

    private func loadCatalogsInternal() async throws {
        self.syncStatus = .loadingCatalogs

        let service = LightroomCloudService()
        self.selectedCatalogID = try await service.fetchCatalog(
            apiKey: self.clientID,
            accessToken: self.accessToken
        ).id

        self.appendLog("Catalog loaded.", type: .success)

        self.syncStatus = .idle
    }
}

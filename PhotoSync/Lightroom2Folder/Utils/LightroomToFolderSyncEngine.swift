//
//  LightroomToFolderSyncEngine.swift
//  PhotoSync
//

import Foundation

final class LightroomToFolderSyncEngine {
    private let service: LightroomCloudService
    private let log: (LightroomSyncLogEntry) -> Void
    private let progress: (Int, Int) -> Void

    private var totalAssets: Int = 0
    private var processedAssets: Int = 0

    init(
        service: LightroomCloudService,
        log: @escaping (LightroomSyncLogEntry) -> Void,
        progress: @escaping (Int, Int) -> Void
    ) {
        self.service = service
        self.log = log
        self.progress = progress
    }

    func run(
        configuration: LightroomCloudConfiguration,
        selectedFolderID: String,
        allFolders: [LightroomFolder],
        targetRootURL: URL
    ) async throws {
        let folderMap = Dictionary(uniqueKeysWithValues: allFolders.map { ($0.id, $0) })
        guard let selectedFolder = folderMap[selectedFolderID] else {
            throw LightroomSyncError.folderNotFound
        }

        let foldersToSync = self.collectDescendants(of: selectedFolder, from: allFolders)
        let assetsByFolder = try await self.scanAssets(
            folders: foldersToSync,
            configuration: configuration
        )

        self.log(.init(message: "Exporting to \(targetRootURL.path)", type: .info))

        for folder in foldersToSync {
            try Task.checkCancellation()

            guard let assets = assetsByFolder[folder.id], !assets.isEmpty else { continue }

            let relativePath = self.relativePathComponents(
                from: folder,
                rootFolderID: selectedFolder.id,
                folderMap: folderMap
            )
            let destinationDirectory = self.directoryURL(root: targetRootURL, pathComponents: relativePath)
            try self.ensureDirectoryExists(at: destinationDirectory)

            self.log(.init(message: "Folder '\(folder.name)' — \(assets.count) photo(s)", type: .info))

            for asset in assets {
                try Task.checkCancellation()
                do {
                    try await self.exportAsset(
                        asset,
                        to: destinationDirectory,
                        configuration: configuration
                    )

                    self.log(.init(message: "Asset exported", type: .info))
                }
                catch {
                    self.log(.init(message: "Error exporting asset", type: .error))
                }
            }
        }
    }

    private func scanAssets(
        folders: [LightroomFolder],
        configuration: LightroomCloudConfiguration
    ) async throws -> [String: [LightroomAsset]] {
        self.totalAssets = 0
        self.processedAssets = 0

        var assetsByFolder: [String: [LightroomAsset]] = [:]
        self.log(.init(message: "Scanning selected Lightroom folder tree…", type: .info))

        for folder in folders {
            try Task.checkCancellation()
            let assets = try await self.service.fetchAssets(folderID: folder.id, configuration: configuration)
            assetsByFolder[folder.id] = assets
            self.totalAssets += assets.count
            self.log(.init(message: "Scanned '\(folder.name)': \(assets.count) asset(s)", type: .info))
        }

        self.log(.init(message: "Found \(self.totalAssets) asset(s) to export.", type: .info))
        self.progress(0, self.totalAssets)
        return assetsByFolder
    }

    private func exportAsset(
        _ asset: LightroomAsset,
        to destinationDirectory: URL,
        configuration: LightroomCloudConfiguration
    ) async throws {
        let safeFileName = self.normalizedJPGFileName(for: asset.fileName)
        let initialURL = destinationDirectory.appendingPathComponent(safeFileName)

        if FileManager.default.fileExists(atPath: initialURL.path) {
            self.log(.init(message: "  Skip (exists): \(safeFileName)", type: .info))
            self.processedAssets += 1
            self.progress(self.processedAssets, self.totalAssets)
            return
        }

        let destinationURL = self.uniqueFileURL(startingAt: initialURL)
        let remoteURL = try await self.resolveDownloadURL(for: asset, configuration: configuration)

        do {
            try await self.service.downloadAsset(from: remoteURL, to: destinationURL, configuration: configuration)
            self.log(.init(message: "  Exported: \(destinationURL.lastPathComponent)", type: .success))
        } catch {
            self.log(.init(message: "  Error exporting \(safeFileName): \(error.localizedDescription)", type: .error))
        }

        self.processedAssets += 1
        self.progress(self.processedAssets, self.totalAssets)
    }

    private func resolveDownloadURL(
        for asset: LightroomAsset,
        configuration: LightroomCloudConfiguration
    ) async throws -> URL {
        if let directURL = asset.downloadURL {
            return directURL
        }

        return try await self.service.resolveJPGDownloadURL(
            assetID: asset.id,
            configuration: configuration
        )
    }

    private func collectDescendants(
        of root: LightroomFolder,
        from allFolders: [LightroomFolder]
    ) -> [LightroomFolder] {
        var childrenByParentID: [String: [LightroomFolder]] = [:]
        for folder in allFolders {
            guard let parentID = folder.parentID else { continue }
            childrenByParentID[parentID, default: []].append(folder)
        }

        var queue: [LightroomFolder] = [root]
        var output: [LightroomFolder] = []

        while !queue.isEmpty {
            let current = queue.removeFirst()
            output.append(current)
            let children = (childrenByParentID[current.id] ?? []).sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
            queue.append(contentsOf: children)
        }

        return output
    }

    private func relativePathComponents(
        from folder: LightroomFolder,
        rootFolderID: String,
        folderMap: [String: LightroomFolder]
    ) -> [String] {
        var components: [String] = []
        var current: LightroomFolder? = folder

        while let value = current, value.id != rootFolderID {
            components.insert(value.name, at: 0)
            if let parentID = value.parentID {
                current = folderMap[parentID]
            } else {
                current = nil
            }
        }

        return components
    }

    private func directoryURL(root: URL, pathComponents: [String]) -> URL {
        pathComponents.reduce(root) { partial, pathComponent in
            partial.appendingPathComponent(pathComponent)
        }
    }

    private func ensureDirectoryExists(at url: URL) throws {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw LightroomSyncError.failedToCreateDirectory(url, error)
        }
    }

    private func normalizedJPGFileName(for fileName: String) -> String {
        let cleaned = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return UUID().uuidString + ".jpg" }

        let baseName = URL(fileURLWithPath: cleaned).deletingPathExtension().lastPathComponent
        return baseName + ".jpg"
    }

    private func uniqueFileURL(startingAt baseURL: URL) -> URL {
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            return baseURL
        }

        let folder = baseURL.deletingLastPathComponent()
        let stem = baseURL.deletingPathExtension().lastPathComponent
        let ext = baseURL.pathExtension

        var index = 2
        while true {
            let candidate = folder.appendingPathComponent("\(stem)-\(index).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }
}

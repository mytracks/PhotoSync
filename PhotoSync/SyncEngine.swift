//
//  SyncEngine.swift
//  PhotoSync
//

import Foundation
import Photos

/// Coordinates scanning and syncing a folder tree into the Photos library.
final class SyncEngine {

    private let photoService: PhotoLibraryService
    private let log: (SyncLogEntry) -> Void
    private let progress: (Int, Int) -> Void  // (completed, total)

    private var totalPhotos = 0
    private var processedPhotos = 0

    init(
        photoService: PhotoLibraryService,
        log: @escaping (SyncLogEntry) -> Void,
        progress: @escaping (Int, Int) -> Void
    ) {
        self.photoService = photoService
        self.log = log
        self.progress = progress
    }

    // MARK: - Entry Point

    func run(rootURL: URL) async throws {
        // 1. Request authorization
        guard await photoService.requestAuthorization() else {
            throw SyncError.notAuthorized
        }

        // 2. Scan folder tree
        log(.init(message: "Scanning \(rootURL.path)…", type: .info))
        let scanner = FolderScanner()
        let tree: FolderNode
        do {
            tree = try scanner.scan(url: rootURL)
        } catch {
            throw SyncError.scanFailed(rootURL, error)
        }

        totalPhotos = tree.totalPhotoCount
        log(.init(message: "Found \(totalPhotos) photo(s) to process.", type: .info))
        progress(0, totalPhotos)

        // 3. Sync
        try await syncNode(tree, parentFolder: nil)
    }

    // MARK: - Recursive Sync

    private func syncNode(_ node: FolderNode, parentFolder: PHCollectionList?) async throws {

        // --- Folder with subfolders → create a Photos folder ---
        if node.hasSubfolders {
            let folder = try await photoService.findOrCreateFolder(named: node.name, in: parentFolder)
            let isNew = folder.localizedTitle == node.name  // always true, just for clarity
            log(.init(
                message: "\(isNew ? "Folder" : "Folder (exists)"): \(node.name)",
                type: .info
            ))

            for child in node.children {
                try await syncNode(child, parentFolder: folder)
            }
        }

        // --- Folder with photos → create a Photos album ---
        if node.hasPhotos {
            let album = try await photoService.findOrCreateAlbum(named: node.name, in: parentFolder)
            log(.init(message: "Album '\(node.name)' — \(node.photoFiles.count) photo(s)", type: .info))

            let existing = photoService.existingFilenames(in: album)

            for photoURL in node.photoFiles {
                let filename = photoURL.lastPathComponent
                if existing.contains(filename) {
                    log(.init(message: "  Skip (exists): \(filename)", type: .info))
                    processedPhotos += 1
                    progress(processedPhotos, totalPhotos)
                    continue
                }

                do {
                    try await photoService.addPhoto(at: photoURL, to: album, existingFilenames: existing)
                    log(.init(message: "  Added: \(filename)", type: .success))
                } catch {
                    log(.init(
                        message: "  Error adding \(filename): \(error.localizedDescription)",
                        type: .error
                    ))
                }

                processedPhotos += 1
                progress(processedPhotos, totalPhotos)
            }
        }
    }
}

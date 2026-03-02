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

    /// Run the sync.
    /// - Parameters:
    ///   - rootURL:    The local folder to sync.
    ///   - baseFolder: The Photos library folder to use as the sync root.
    ///                 Pass `nil` to target the top level of the library.
    func run(rootURL: URL, baseFolder: PHCollectionList? = nil) async throws {
        // 1. Request authorization
        guard await self.photoService.requestAuthorization() else {
            throw SyncError.notAuthorized
        }

        // 2. Scan folder tree
        self.log(.init(message: "Scanning \(rootURL.path)…", type: .info))
        let scanner = FolderScanner()
        let tree: FolderNode
        do {
            tree = try scanner.scan(url: rootURL)
        } catch {
            throw SyncError.scanFailed(rootURL, error)
        }

        self.totalPhotos = tree.totalPhotoCount
        self.log(.init(message: "Found \(self.totalPhotos) photo(s) to process.", type: .info))
        self.progress(0, self.totalPhotos)

        // 3. Sync the *contents* of the root folder directly under baseFolder,
        //    without creating a Photos item for the root folder itself.
        for child in tree.children {
            try Task.checkCancellation()
            try await self.syncNode(child, parentFolder: baseFolder)
        }
        if tree.hasPhotos {
            try Task.checkCancellation()
            // Photos sitting directly in the root go into an album named after the root folder.
            try await self.syncPhotos(tree.photoFiles, albumName: tree.name, in: baseFolder)
        }
    }

    // MARK: - Recursive Sync

    private func syncNode(_ node: FolderNode, parentFolder: PHCollectionList?) async throws {

        // --- Folder with subfolders → create a Photos folder ---
        if node.hasSubfolders {
            let folder = try await self.photoService.findOrCreateFolder(named: node.name, in: parentFolder)
            self.log(.init(message: "Folder: \(node.name)", type: .info))

            for child in node.children {
                try Task.checkCancellation()
                try await self.syncNode(child, parentFolder: folder)
            }
        }

        // --- Folder with photos → create a Photos album ---
        if node.hasPhotos {
            try await self.syncPhotos(node.photoFiles, albumName: node.name, in: parentFolder)
        }
    }

    private func syncPhotos(_ photoFiles: [URL], albumName: String, in parent: PHCollectionList?) async throws {
        let album = try await self.photoService.findOrCreateAlbum(named: albumName, in: parent)
        self.log(.init(message: "Album '\(albumName)' — \(photoFiles.count) photo(s)", type: .info))

        let existing = self.photoService.existingFilenames(in: album)

        for photoURL in photoFiles {
            try Task.checkCancellation()
            let filename = photoURL.lastPathComponent
            if existing.contains(filename) {
                self.log(.init(message: "  Skip (exists): \(filename)", type: .info))
                self.processedPhotos += 1
                self.progress(self.processedPhotos, self.totalPhotos)
                continue
            }

            do {
                try await self.photoService.addPhoto(at: photoURL, to: album, existingFilenames: existing)
                self.log(.init(message: "  Added: \(filename)", type: .success))
            } catch {
                self.log(.init(
                    message: "  Error adding \(filename): \(error.localizedDescription)",
                    type: .error
                ))
            }

            self.processedPhotos += 1
            self.progress(self.processedPhotos, self.totalPhotos)
        }
    }
}

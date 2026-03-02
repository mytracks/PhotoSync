//
//  PhotoLibraryService.swift
//  PhotoSync
//

import Foundation
import Photos

/// Wraps all PhotoKit read and write operations.
struct PhotoLibraryService {

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized
    }

    // MARK: - Lookup

    /// Fetch all top-level `PHCollectionList` (folder) items in the Photos library.
    func fetchTopLevelFolders() -> [PHCollectionList] {
        let result = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        return self.collectFolders(from: result)
    }

    /// Fetch direct child `PHCollectionList` (sub-folder) items inside `parent`.
    func fetchSubfolders(in parent: PHCollectionList) -> [PHCollectionList] {
        let result = PHCollection.fetchCollections(in: parent, options: nil)
        return self.collectFolders(from: result)
    }

    private func collectFolders(from result: PHFetchResult<PHCollection>) -> [PHCollectionList] {
        var folders: [PHCollectionList] = []
        for i in 0..<result.count {
            if let folder = result[i] as? PHCollectionList {
                folders.append(folder)
            }
        }
        return folders
    }

    /// Find a top-level user collection (folder or album) by title.
    func findTopLevelCollection(named name: String) -> PHCollection? {
        let result = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        return self.firstCollection(in: result, named: name)
    }

    /// Find a direct child collection inside `parent` by title.
    func findCollection(named name: String, in parent: PHCollectionList) -> PHCollection? {
        let result = PHCollection.fetchCollections(in: parent, options: nil)
        return self.firstCollection(in: result, named: name)
    }

    private func firstCollection(in result: PHFetchResult<PHCollection>, named name: String) -> PHCollection? {
        for i in 0..<result.count {
            let col = result[i]
            if col.localizedTitle == name { return col }
        }
        return nil
    }

    /// Return all existing photo filenames in `album`.
    func existingFilenames(in album: PHAssetCollection) -> Set<String> {
        let assets = PHAsset.fetchAssets(in: album, options: nil)
        var names = Set<String>()
        for i in 0..<assets.count {
            let resources = PHAssetResource.assetResources(for: assets[i])
            for resource in resources where resource.type == .photo || resource.type == .fullSizePhoto {
                names.insert(resource.originalFilename)
            }
        }
        return names
    }

    // MARK: - Create Folder

    /// Find or create a `PHCollectionList` (Photos folder) inside `parent`, or at the top level.
    func findOrCreateFolder(named name: String, in parent: PHCollectionList?) async throws -> PHCollectionList {
        // Check existing
        if let parent = parent {
            if let existing = self.findCollection(named: name, in: parent) as? PHCollectionList {
                return existing
            }
        } else {
            if let existing = self.findTopLevelCollection(named: name) as? PHCollectionList {
                return existing
            }
        }

        // Create new
        var placeholderID: String?

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: name)
            placeholderID = request.placeholderForCreatedCollectionList.localIdentifier

            if let parent = parent,
               let parentRequest = PHCollectionListChangeRequest(for: parent) {
                parentRequest.addChildCollections(
                    [request.placeholderForCreatedCollectionList] as NSFastEnumeration
                )
            }
        }

        guard let id = placeholderID,
              let folder = PHCollectionList.fetchCollectionLists(
                  withLocalIdentifiers: [id], options: nil
              ).firstObject
        else {
            throw SyncError.failedToCreateFolder(name)
        }
        return folder
    }

    // MARK: - Create Album

    /// Find or create a `PHAssetCollection` (Photos album) inside `parent`, or at the top level.
    func findOrCreateAlbum(named name: String, in parent: PHCollectionList?) async throws -> PHAssetCollection {
        // Check existing
        if let parent = parent {
            if let existing = self.findCollection(named: name, in: parent) as? PHAssetCollection {
                return existing
            }
        } else {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "title = %@", name)
            if let existing = PHAssetCollection.fetchAssetCollections(
                with: .album, subtype: .albumRegular, options: options
            ).firstObject {
                return existing
            }
        }

        // Create new
        var placeholderID: String?

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            placeholderID = request.placeholderForCreatedAssetCollection.localIdentifier

            if let parent = parent,
               let parentRequest = PHCollectionListChangeRequest(for: parent) {
                parentRequest.addChildCollections(
                    [request.placeholderForCreatedAssetCollection] as NSFastEnumeration
                )
            }
        }

        guard let id = placeholderID,
              let album = PHAssetCollection.fetchAssetCollections(
                  withLocalIdentifiers: [id], options: nil
              ).firstObject
        else {
            throw SyncError.failedToCreateAlbum(name)
        }
        return album
    }

    // MARK: - Add Photo

    /// Add the image at `url` to `album`. Does nothing if the filename already exists.
    func addPhoto(at url: URL, to album: PHAssetCollection, existingFilenames: Set<String>) async throws {
        let filename = url.lastPathComponent
        guard !existingFilenames.contains(filename) else { return }

        try await PHPhotoLibrary.shared().performChanges {
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = false
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, fileURL: url, options: options)

            if let albumRequest = PHAssetCollectionChangeRequest(for: album),
               let placeholder = creationRequest.placeholderForCreatedAsset {
                albumRequest.addAssets([placeholder] as NSFastEnumeration)
            }
        }
    }
}

//
//  FolderScanner.swift
//  PhotoSync
//

import Foundation

struct FolderScanner {

    static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif",
        "tiff", "tif", "gif", "bmp",
        "raw", "cr2", "cr3", "nef", "arw", "orf", "rw2", "dng",
        "webp", "avif"
    ]

    /// Recursively scan `url` and return a FolderNode tree.
    func scan(url: URL) throws -> FolderNode {
        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        var children: [FolderNode] = []
        var photoFiles: [URL] = []

        for item in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                let child = try self.scan(url: item)
                children.append(child)
            } else if Self.imageExtensions.contains(item.pathExtension.lowercased()) {
                photoFiles.append(item)
            }
        }

        return FolderNode(
            url: url,
            name: url.lastPathComponent,
            children: children,
            photoFiles: photoFiles
        )
    }
}

//
//  FolderNode.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 03.03.26.
//

import Foundation

struct FolderNode {
    let url: URL
    let name: String
    var children: [FolderNode]   // subdirectories
    var photoFiles: [URL]        // image files directly in this folder

    var hasSubfolders: Bool { !self.children.isEmpty }
    var hasPhotos: Bool { !self.photoFiles.isEmpty }

    /// Total number of photos in this node and all descendants
    var totalPhotoCount: Int {
        self.photoFiles.count + self.children.reduce(0) { $0 + $1.totalPhotoCount }
    }
}

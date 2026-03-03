//
//  FolderListView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 03.03.26.
//

import SwiftUI
import Photos

struct FolderListView: View {
    let folders: [PHCollectionList]
    let onSelect: (PHCollectionList) -> Void
    
    var body: some View {
        if self.folders.isEmpty {
            Text("No folders found.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(self.folders, id: \.localIdentifier) { folder in
                FolderRowView(folder: folder, onSelect: self.onSelect)
            }
        }
    }
}

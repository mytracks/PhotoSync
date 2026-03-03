//
//  LibraryFolderPickerView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 03.03.26.
//

import SwiftUI
import Photos

struct LibraryFolderPickerView: View {
    let folders: [PHCollectionList]
    let onSelect: (PHCollectionList) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            FolderListView(folders: self.folders, onSelect: self.onSelect)
                .navigationTitle("Select Target Folder")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            self.onCancel()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
        }
        .frame(minWidth: 320, minHeight: 320)
    }
}


//
//  FolderRowView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 03.03.26.
//

import SwiftUI
import Photos

struct FolderRowView: View {
    let folder: PHCollectionList
    let onSelect: (PHCollectionList) -> Void
    
    private let service = PhotoLibraryService()
    
    private var children: [PHCollectionList] {
        self.service.fetchSubfolders(in: self.folder)
    }
    
    var body: some View {
        HStack {
            if self.children.isEmpty {
                // No subfolders
                Label(self.folder.localizedTitle ?? "Unnamed", systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            else {
                // there are subfolders
                NavigationLink {
                    FolderListView(folders: self.children, onSelect: self.onSelect)
                        .navigationTitle(self.folder.localizedTitle ?? "Unnamed")
                } label: {
                    Label(self.folder.localizedTitle ?? "Unnamed", systemImage: "folder")
                }
            }
            
            Spacer()
            
            Button("Select") {
                self.onSelect(self.folder)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.tint)
        }
    }
}

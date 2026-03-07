//
//  Lightroom2FolderView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI

struct Lightroom2FolderView: View {
    @Environment(AdobeAuthManager.self) var authManager
    @Environment(LightroomSourceProvider.self) var sourceProvider
    @Environment(SyncEngine.self) var syncEngine

    @State private var selectedAlbum: Album? = nil
    @State private var targetFolder: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: Header
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Sync photos from Adobe Lightroom CC to your local hard drive")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                if self.authManager.isAuthorized {
                    if let albums = self.sourceProvider.albums, albums.count > 0 {
                        Picker("Album", selection: self.$selectedAlbum) {
                            ForEach(albums) { album in
                                Text(album.name)
                                    .tag(album)
                            }
                        }
                        .onChange(of: self.sourceProvider.albums) { _, albums in
                            if self.selectedAlbum == nil {
                                self.selectedAlbum = albums?.first
                            }
                        }
                    }
                    
                    Button("Choose Folder…") {
                        self.selectTargetFolder()
                    }
                    
                    Button("Sync") {
                        if let selectedAlbum {
                            let configuration = LightroomSourceConfiguration(rootAlbum: selectedAlbum)
                            self.syncEngine.sync(sourceProvider: self.sourceProvider, sourceConfiguration: configuration)
                        }
                    }
                    .disabled(self.selectedAlbum == nil || self.targetFolder == nil)
                }
                else {
                    Button("Sign in…") {
                        self.authManager.authenticate()
                    }
                }
            }
            .padding()
        }
    }
    
    private func selectTargetFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the target folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            self.targetFolder = panel.url
        }
    }
}

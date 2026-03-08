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
    @Environment(FilesystemTargetProvider.self) var targetProvider
    @Environment(SyncEngine.self) var syncEngine

    @State private var selectedFolder: LightroomAlbum? = nil
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
                    if let folders = self.sourceProvider.folders, folders.count > 0 {
                        Picker("Folder", selection: self.$selectedFolder) {
                            ForEach(folders) { folder in
                                Text(folder.name)
                                    .tag(folder)
                            }
                        }
                        .onChange(of: self.sourceProvider.folders) { _, folders in
                            if self.selectedFolder == nil {
                                self.selectedFolder = folders?.first
                            }
                        }
                    }
                    
                    Button("Choose Folder…") {
                        self.selectTargetFolder()
                    }
                    
                    Button("Sync") {
                        if let selectedFolder, let targetFolder {
                            let sourceConfiguration = LightroomSourceConfiguration(rootFolder: selectedFolder)
                            let targetConfiguration = FilesystemTargetConfiguration(rootFolder: targetFolder)

                            let syncOptions = SyncOptions(createRootSourceFolderAsTargetFolder: true)

                            self.syncEngine.sync(
                                sourceProvider: self.sourceProvider,
                                sourceConfiguration: sourceConfiguration,
                                targetProvider: self.targetProvider,
                                targetConfiguration: targetConfiguration,
                                syncOptions: syncOptions
                            )
                        }
                    }
                    .disabled(self.selectedFolder == nil || self.targetFolder == nil)
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

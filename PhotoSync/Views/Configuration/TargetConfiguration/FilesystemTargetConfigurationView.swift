//
//  FilesystemTargetConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct FilesystemTargetConfigurationView: View {
    @Environment(FilesystemTargetProvider.self) var targetProvider: FilesystemTargetProvider
    
    @State private var targetFolder: URL? = nil
    
    #if os(iOS)
    @State private var showFolderPicker: Bool = false
    #endif
    
    let configHandler: (FilesystemTargetProvider, FilesystemTargetConfiguration) -> ()
    
    init(configHandler: @escaping (FilesystemTargetProvider, FilesystemTargetConfiguration) -> ()) {
        self.configHandler = configHandler
    }
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
            Text("Folder:")
            
            if let targetFolder = self.targetFolder, let basename = targetFolder.pathComponents.last {
                Text(basename)
                    .fontDesign(.monospaced)
                    .fontWeight(.light)
                Button("…") {
                    self.selectTargetFolder()
                }
            } else {
                Button("Select Folder…") {
                    self.selectTargetFolder()
                }
            }
        }
        .onChange(of: self.targetFolder) {
            let config = FilesystemTargetConfiguration(rootFolder: self.targetFolder)
            self.configHandler(self.targetProvider, config)
        }
        #if os(iOS)
        .sheet(isPresented: self.$showFolderPicker) {
            FolderPicker { folderURL in
                self.showFolderPicker = false
                self.targetFolder = folderURL
            }
        }
        #endif
    }
    
    private func selectTargetFolder() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the target folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            self.targetFolder = panel.url
        }
        #endif

#if os(iOS)
        self.showFolderPicker = true
#endif
    }
}

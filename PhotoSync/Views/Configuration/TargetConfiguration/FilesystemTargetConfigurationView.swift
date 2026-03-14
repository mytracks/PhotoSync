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
    
    let configHandler: (FilesystemTargetProvider, FilesystemTargetConfiguration) -> ()
    
    init(configHandler: @escaping (FilesystemTargetProvider, FilesystemTargetConfiguration) -> ()) {
        self.configHandler = configHandler
    }
    
    var body: some View {
        HStack {
            Text("Folder:")
            if let targetFolder = self.targetFolder, let basename = targetFolder.pathComponents.last {
                Text(basename)
                    .fontDesign(.monospaced)
                    .fontWeight(.light)
            } else {
                Text("No folder selected")
                    .fontWeight(.light)
            }
            Button("Choose Folder…") {
                self.selectTargetFolder()
            }
        }
        .onChange(of: self.targetFolder) {
            let config = FilesystemTargetConfiguration(rootFolder: self.targetFolder)
            self.configHandler(self.targetProvider, config)
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

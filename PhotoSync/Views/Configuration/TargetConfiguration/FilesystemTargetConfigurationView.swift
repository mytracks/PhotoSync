//
//  FilesystemTargetConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct FilesystemTargetConfigurationView: View {
    @State private var targetFolder: URL? = nil
    
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

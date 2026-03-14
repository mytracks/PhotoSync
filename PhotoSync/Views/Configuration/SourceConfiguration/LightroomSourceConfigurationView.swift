//
//  LightroomSourceConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct LightroomSourceConfigurationView: View {
    @Environment(AdobeAuthManager.self) var authManager
    @Environment(LightroomSourceProvider.self) var sourceProvider
    @State private var selectedFolder: LightroomAlbum? = nil
    
    let configHandler: (LightroomSourceProvider, LightroomSourceConfiguration) -> ()
    
    init(configHandler: @escaping (LightroomSourceProvider, LightroomSourceConfiguration) -> ()) {
        self.configHandler = configHandler
    }
    
    var body: some View {
        Group {
            if self.authManager.isAuthorized {
                HStack {
                    Image(systemName: "folder")
                    Text("Folder:")
                    
                    if self.sourceProvider.state == .loadingAlbums {
                        Text("Loading ...")
                    }
                    
                    if self.sourceProvider.state == .ready {
                        if let folders = self.sourceProvider.folders, folders.count > 0 {
                            Picker(selection: self.$selectedFolder) {
                                ForEach(folders) { folder in
                                    Text(folder.name)
                                        .tag(folder)
                                }
                            } label: {
                                EmptyView()
                            }
                        }
                    }
                }
            }
            else {
                Button("Sign in to Adobe Lightroom …") {
                    self.authManager.authenticate()
                }
            }
        }
        .onChange(of: self.selectedFolder) {
            let config = LightroomSourceConfiguration(rootFolder: self.selectedFolder)
            self.configHandler(self.sourceProvider, config)
        }
    }
}

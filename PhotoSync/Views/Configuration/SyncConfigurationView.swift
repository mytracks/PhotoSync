//
//  SyncConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct SyncConfigurationView: View {
    @Environment(SyncEngine.self) var syncEngine
    
    @State var sourceProvider: (any SourceProvider)?
    @State var sourceConfig: (any SourceConfiguration)?
    @State var targetProvider: (any TargetProvider)?
    @State var targetConfig: (any TargetConfiguration)?

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                GroupBox {
                    SourceConfigurationView() { provider, config in
                        self.sourceProvider = provider
                        self.sourceConfig = config
                    }
                    .padding(4)
                } label: {
                    Label("Source", systemImage: "square.and.arrow.down.on.square")
                        .font(.headline)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                
                GroupBox {
                    TargetConfigurationView() { provider, config in
                        self.targetProvider = provider
                        self.targetConfig = config
                    }
                    .padding(4)
                } label: {
                    Label("Target", systemImage: "square.and.arrow.up.on.square")
                        .font(.headline)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
            
            if let sourceConfig = self.sourceConfig, let targetConfig = self.targetConfig, sourceConfig.canSync && targetConfig.canSync {
                Button("Sync") {
                    self.sync()
                }
            }
        }
    }
    
    private func sync() {
        guard let sourceProvider else { return }
        guard let sourceConfig else { return }
        guard let targetProvider else { return }
        guard let targetConfig else { return }
        
        let syncOptions = SyncOptions(createRootSourceFolderAsTargetFolder: true)
        
        self.syncEngine.sync(sourceProvider: sourceProvider, sourceConfiguration: sourceConfig, targetProvider: targetProvider, targetConfiguration: targetConfig, syncOptions: syncOptions)
    }
}

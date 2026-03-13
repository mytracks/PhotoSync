//
//  SyncConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct SyncConfigurationView: View {
    @State var sourceConfig: (any SourceConfiguration)?
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                GroupBox {
                    SourceConfigurationView() { config in
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
                    TargetConfigurationView()
                        .padding(4)
                } label: {
                    Label("Target", systemImage: "square.and.arrow.up.on.square")
                        .font(.headline)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
            
            if self.sourceConfig != nil {
                Text("Can Sync")
            }
            else {
                Text("Cannot Sync")
            }
        }
    }
}

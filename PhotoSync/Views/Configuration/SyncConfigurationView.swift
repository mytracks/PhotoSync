//
//  SyncConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct SyncConfigurationView: View {
    var body: some View {
        HStack(alignment: .top) {
            GroupBox {
                SourceConfigurationView()
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
    }
}

#Preview {
    SyncConfigurationView()
}

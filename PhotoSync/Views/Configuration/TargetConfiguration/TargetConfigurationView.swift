//
//  TargetConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

enum TargetType: Hashable {
    case lightroom
    case filesystem
    case applePhotos
}

struct TargetConfigurationView: View {
    @State var targetType: TargetType = .filesystem
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: self.$targetType) {
                Text("Adobe Lightroom")
                    .tag(TargetType.lightroom)
                Text("Filesystem")
                    .tag(TargetType.filesystem)
                Text("Apple Photos")
                    .tag(TargetType.applePhotos)
            } label: {
                Text("Target type:")
            }

            if self.targetType == .filesystem {
                FilesystemTargetConfigurationView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

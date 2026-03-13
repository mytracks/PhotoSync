//
//  SourceConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

enum SourceType: Hashable {
    case lightroom
    case filesystem
    case applePhotos
}

struct SourceConfigurationView: View {
    @State var sourceType: SourceType = .lightroom
    
    let sourceConfigHandler: (any SourceConfiguration) -> ()
    
    init(sourceConfigHandler: @escaping (any SourceConfiguration) -> ()) {
        self.sourceConfigHandler = sourceConfigHandler
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker(selection: self.$sourceType) {
                Text("Adobe Lightroom")
                    .tag(SourceType.lightroom)
                Text("Filesystem")
                    .tag(SourceType.filesystem)
                Text("Apple Photos")
                    .tag(SourceType.applePhotos)
            } label: {
                Text("Source type:")
            }
            
            if self.sourceType == .lightroom {
                LightroomSourceConfigurationView() { config in
                    self.sourceConfigHandler(config)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

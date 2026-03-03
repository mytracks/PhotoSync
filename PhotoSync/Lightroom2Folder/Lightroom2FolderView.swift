//
//  Lightroom2FolderView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI
import Photos

struct Lightroom2FolderView: View {
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
            
            Spacer()
        }
    }
}

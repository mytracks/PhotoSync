//
//  MainView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI
import Photos

struct MainView: View {
    var body: some View {
        TabView {
            Tab("Folder 􀰑 Photo Library", systemImage: "photo.stack") {
                Folder2LibraryView()
            }
            Tab("Lightroom 􀰑 Folder", systemImage: "l.square") {
                Lightroom2FolderView()
            }
        }
        .frame(minWidth: 600, minHeight: 480)
    }
}

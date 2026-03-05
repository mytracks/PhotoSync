//
//  Lightroom2FolderView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI

struct Lightroom2FolderView: View {
    @State private var viewModel = Lightroom2FolderViewModel()

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
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Access Token") {
                        HStack(spacing: 8) {
                            SecureField("OAuth Access Token", text: self.$viewModel.accessToken)
                                .textFieldStyle(.roundedBorder)
                                .disabled(self.viewModel.syncStatus.isActive || self.viewModel.isAuthorizing)

                            Button("Sign in…") {
                                self.viewModel.signInWithAdobe()
                            }
                            .disabled(!self.viewModel.canStartOAuth)

                            if self.viewModel.isAuthorizing {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }

//                    LabeledContent("Catalog") {
//                        HStack(spacing: 8) {
//                            if self.viewModel.availableCatalogs.isEmpty {
//                                Text("No catalogs loaded")
//                                    .foregroundStyle(.secondary)
//                                    .frame(maxWidth: .infinity, alignment: .leading)
//                            } else {
//                                Picker("Catalog", selection: self.$viewModel.selectedCatalogID) {
//                                    ForEach(self.viewModel.availableCatalogs) { catalog in
//                                        Text(catalog.name).tag(Optional(catalog.id))
//                                    }
//                                }
//                                .pickerStyle(.menu)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .disabled(self.viewModel.syncStatus.isActive)
//                            }
//
//                            Button("Reload") {
//                                self.viewModel.loadCatalogs()
//                            }
//                            .disabled(!self.viewModel.canLoadCatalogs)
//                        }
//                    }

                    if let oauthStatusMessage = self.viewModel.oauthStatusMessage {
                        Text(oauthStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } label: {
                Label("Lightroom Cloud API", systemImage: "key.horizontal")
                    .font(.headline)
            }
            .padding()

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Button("Load Folders…") {
                            self.viewModel.loadFolders()
                        }
                        .disabled(!self.viewModel.canLoadFolders)

                        Text("\(self.viewModel.availableFolders.count) loaded")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }

                    if self.viewModel.availableFolders.isEmpty {
                        Text("Load folders first to select the Lightroom source folder.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        Picker("Lightroom Folder", selection: self.$viewModel.selectedFolderID) {
                            ForEach(self.viewModel.availableFolders) { folder in
                                Text(folder.name).tag(Optional(folder.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(self.viewModel.syncStatus.isActive)
                    }
                }
            } label: {
                Label("Source in Lightroom", systemImage: "folder.badge.questionmark")
                    .font(.headline)
            }
            .padding([.horizontal, .bottom])

            GroupBox {
                HStack(spacing: 12) {
                    Button("Choose Target Folder…") {
                        self.viewModel.selectTargetFolder()
                    }
                    .disabled(self.viewModel.syncStatus.isActive)

                    if let targetFolder = self.viewModel.targetFolderURL {
                        Label(targetFolder.path, systemImage: "folder")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No target folder selected")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } label: {
                Label("Local Target Folder", systemImage: "externaldrive")
                    .font(.headline)
            }
            .padding([.horizontal, .bottom])

            HStack(alignment: .center, spacing: 16) {
                if self.viewModel.syncStatus.isActive {
                    Button(role: .destructive) {
                        self.viewModel.cancelSync()
                    } label: {
                        Label("Cancel", systemImage: "stop.circle")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        self.viewModel.startSync()
                    } label: {
                        Label("Sync to Folder", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.viewModel.canSync)
                }

                Spacer()

                Text(self.viewModel.syncStatus.displayString)
                    .foregroundStyle(self.statusColor)
                    .font(.callout)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if self.viewModel.syncStatus.isActive || self.viewModel.syncStatus == .completed || self.viewModel.syncStatus == .cancelled {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: self.viewModel.progressFraction)
                        .progressViewStyle(.linear)

                    HStack {
                        Text("\(self.viewModel.completedAssets) / \(self.viewModel.totalAssets) photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", self.viewModel.progressFraction * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(self.viewModel.logEntries) { entry in
                            Text(entry.message)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(self.logColor(for: entry.type))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(entry.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: self.viewModel.logEntries.count) {
                    if let last = self.viewModel.logEntries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch self.viewModel.syncStatus {
        case .completed: return .green
        case .cancelled: return .orange
        case .failed: return .red
        default: return .secondary
        }
    }

    private func logColor(for type: LightroomSyncLogEntry.LogType) -> Color {
        switch type {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

//
//  Folder2LibraryView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI
import Photos

struct Folder2LibraryView: View {
    @State private var viewModel = Folder2LibraryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Sync photos from local hard drive to your Photo Library")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()

            Divider()

            // MARK: Folder Selection
            GroupBox {
                HStack(spacing: 12) {
                    Button("Choose Folder…") {
                        self.viewModel.selectFolder()
                    }
                    .disabled(self.viewModel.syncStatus.isActive)

                    if let url = self.viewModel.selectedFolderURL {
                        Label(url.path, systemImage: "folder")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No folder selected")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } label: {
                Label("Source Folder", systemImage: "folder.badge.questionmark")
                    .font(.headline)
            }
            .padding()

            // MARK: Library Folder Selection
            GroupBox {
                HStack(spacing: 12) {
                    Button("Choose Library Folder…") {
                        self.viewModel.selectLibraryFolder()
                    }
                    .disabled(self.viewModel.syncStatus.isActive)

                    if let title = self.viewModel.selectedLibraryFolderTitle {
                        Label(title, systemImage: "photo.on.rectangle")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button("Clear") {
                            self.viewModel.clearLibraryFolder()
                        }
                        .foregroundStyle(.secondary)
                        .disabled(self.viewModel.syncStatus.isActive)
                    } else {
                        Text("Photo Library Root")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } label: {
                Label("Target in Photo Library", systemImage: "rectangle.stack.badge.person.crop")
                    .font(.headline)
            }
            .padding([.horizontal, .bottom])

            // MARK: Sync Controls
            HStack(alignment: .center, spacing: 16) {
                if self.viewModel.syncStatus.isActive {
                    Button(role: .destructive) {
                        self.viewModel.cancelSync()
                    } label: {
                        Label("Cancel", systemImage: "stop.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
                else {
                    Button {
                        self.viewModel.startSync()
                    } label: {
                        Label("Sync to Photos", systemImage: "arrow.triangle.2.circlepath")
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

            // MARK: Progress Bar
            if self.viewModel.syncStatus.isActive || self.viewModel.syncStatus == .completed || self.viewModel.syncStatus == .cancelled {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: self.viewModel.progressFraction)
                        .progressViewStyle(.linear)

                    HStack {
                        Text("\(self.viewModel.completedPhotos) / \(self.viewModel.totalPhotos) photos")
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

            // MARK: Log
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
        .sheet(isPresented: self.$viewModel.showingLibraryFolderPicker) {
            LibraryFolderPickerView(
                folders: self.viewModel.availableLibraryFolders,
                onSelect: { folder in
                    self.viewModel.selectedLibraryFolder = folder
                    self.viewModel.showingLibraryFolderPicker = false
                },
                onCancel: {
                    self.viewModel.showingLibraryFolderPicker = false
                }
            )
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch self.viewModel.syncStatus {
        case .completed: return .green
        case .cancelled: return .orange
        case .failed: return .red
        default: return .secondary
        }
    }

    private func logColor(for type: SyncLogEntry.LogType) -> Color {
        switch type {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .debug: return .blue
        }
    }
}

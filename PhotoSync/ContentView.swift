//
//  ContentView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI

struct ContentView: View {

    @State private var viewModel = PhotoSyncViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Header
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("PhotoSync")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding()

            Divider()

            // MARK: Folder Selection
            GroupBox {
                HStack(spacing: 12) {
                    Button("Choose Folder…") {
                        viewModel.selectFolder()
                    }
                    .disabled(viewModel.syncStatus.isActive)

                    if let url = viewModel.selectedFolderURL {
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

            // MARK: Sync Controls
            HStack(alignment: .center, spacing: 16) {
                Button {
                    viewModel.startSync()
                } label: {
                    Label("Sync to Photos", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSync)

                Spacer()

                Text(viewModel.syncStatus.displayString)
                    .foregroundStyle(statusColor)
                    .font(.callout)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // MARK: Progress Bar
            if viewModel.syncStatus.isActive || viewModel.syncStatus == .completed {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: viewModel.progressFraction)
                        .progressViewStyle(.linear)

                    HStack {
                        Text("\(viewModel.completedPhotos) / \(viewModel.totalPhotos) photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", viewModel.progressFraction * 100))
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
                        ForEach(viewModel.logEntries) { entry in
                            Text(entry.message)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(logColor(for: entry.type))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(entry.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: viewModel.logEntries.count) {
                    if let last = viewModel.logEntries.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 480)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch viewModel.syncStatus {
        case .completed: return .green
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
        }
    }
}

#Preview {
    ContentView()
}

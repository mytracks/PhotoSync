//
//  SyncProgressView.swift
//  PhotoSync
//

import SwiftUI

struct SyncProgressView: View {
    @Environment(SyncEngine.self) private var syncEngine
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            
            // Animation Header
            ZStack {
                // Outer dashed ring
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 4, dash: [10, 15]))
                    .foregroundColor(.blue.opacity(0.4))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(isAnimating ? Animation.linear(duration: 8).repeatForever(autoreverses: false) : .default, value: isAnimating)
                
                // Inner pulsing ring
                Circle()
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .opacity(isAnimating ? 0.8 : 1.0)
                    .animation(isAnimating ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: isAnimating)
                
                // Center Icon
                Image(systemName: centerIconName(for: syncEngine.status))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(centerIconColor(for: syncEngine.status))
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(isAnimating ? Animation.linear(duration: 3).repeatForever(autoreverses: false) : .default, value: isAnimating)
            }
            .frame(height: 180)
            
            // Status and Log
            VStack(spacing: 16) {
                Text(syncEngine.status.displayString)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let lastLog = syncEngine.logEntries.last {
                    Text(lastLog.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .top)
                        .id(lastLog.id) // Force view update on new log
                        .transition(.opacity)
                        .animation(.easeInOut, value: lastLog.id)
                } else {
                    Text("Ready to sync...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(minHeight: 60)
                }
                
                // Stats summary
                HStack(spacing: 24) {
                    StatView(
                        title: "Photos Synced",
                        value: "\(syncEngine.logEntries.filter { $0.message.contains("Loading JPEG data") }.count)",
                        icon: "photo.fill"
                    )
                    
                    StatView(
                        title: "Folders Processed",
                        value: "\(syncEngine.logEntries.filter { $0.message.contains("Processing subfolders") }.count)",
                        icon: "folder.fill"
                    )
                }
                .padding(.top, 10)
                
                if syncEngine.status == .completed || isFailedStatus(syncEngine.status) {
                    Button(action: {
                        syncEngine.status = .idle
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            if syncEngine.status.isActive {
                isAnimating = true
            }
        }
        .onChange(of: syncEngine.status) { _, newStatus in
            isAnimating = newStatus.isActive
        }
    }
    
    private func isFailedStatus(_ status: SyncStatus) -> Bool {
        if case .failed(_) = status { return true }
        return false
    }
    
    private func centerIconName(for status: SyncStatus) -> String {
        if status == .completed { return "checkmark.circle.fill" }
        if isFailedStatus(status) { return "xmark.circle.fill" }
        if status.isActive { return "arrow.triangle.2.circlepath" }
        return "photo.circle"
    }
    
    private func centerIconColor(for status: SyncStatus) -> Color {
        if status == .completed { return .green }
        if isFailedStatus(status) { return .red }
        return .blue
    }
}

fileprivate struct StatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 100)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

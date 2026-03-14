//
//  LogView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 08.03.26.
//

import SwiftUI

struct LogView: View {
    @Environment(SyncEngine.self) private var syncEngine
    
    var body: some View {
        // MARK: Log
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(self.syncEngine.logEntries) { entry in
                        Text(entry.message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(self.logColor(for: entry.type))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(entry.id)
                    }
                }
                .padding(8)
            }
            .onChange(of: self.syncEngine.logEntries.count) {
                if let last = self.syncEngine.logEntries.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .frame(maxHeight: .infinity)
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

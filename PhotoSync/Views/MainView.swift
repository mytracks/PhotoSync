//
//  MainView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI
import OAuthKit

struct MainView: View {
    @Environment(AdobeAuthManager.self) private var authManager
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(SyncEngine.self) private var syncEngine
    
    var body: some View {
        VStack {
            SyncConfigurationView()
            
            Divider()
            
            LogView()
        }
//        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
        .onChange(of: self.authManager.oauth.state) { _, state in
            self.handle(state: state)
        }
    }
    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
#if canImport(WebKit)
        switch state {
        case .empty, .error, .requestingAccessToken, .requestingDeviceCode:
            break
        case .authorizing, .receivedDeviceCode:
            self.openWindow(id: "oauth")
        case .authorized(_, _):
            self.dismissWindow(id: "oauth")
        }
#endif
    }
}

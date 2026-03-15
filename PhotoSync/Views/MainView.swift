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
    
    @State private var showOAuthWindow: Bool = false
    
    var body: some View {
        VStack {
            SyncConfigurationView()
            
            Divider()
            
            LogView()
        }
        #if os(macOS)
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
        #endif
        .onChange(of: self.authManager.oauth.state) { _, state in
            self.handle(state: state)
        }
        .fullScreenCover(isPresented: self.$showOAuthWindow) {
//        .sheet(isPresented: self.$showOAuthWindow) {
            OAWebView(oauth: self.authManager.oauth)
                //.frame(maxWidth: 800, maxHeight: 800)
                .presentationDetents([.large])
        }
    }
    /// Reacts to oauth state changes by opening or closing authorization windows.
    /// - Parameter state: the published state change
    private func handle(state: OAuth.State) {
        switch state {
        case .empty, .error, .requestingAccessToken, .requestingDeviceCode:
            break
        case .authorizing, .receivedDeviceCode:
            self.showOAuthWindow = true
        case .authorized(_, _):
            self.showOAuthWindow = false
        }
    }
}


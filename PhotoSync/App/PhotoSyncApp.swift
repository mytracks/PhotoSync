//
//  PhotoSyncApp.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 02.03.26.
//

import SwiftUI
import OAuthKit

@main
struct PhotoSyncApp: App {
    let authManager: AdobeAuthManager
    let lightroomConnector: LightroomConnector
    let lightroomSourceProvider: LightroomSourceProvider
    let filesystemTargetProvider: FilesystemTargetProvider
    let syncEngine: SyncEngine
    
    init() {
        self.authManager = .init()
        self.lightroomConnector = .init()
        self.lightroomSourceProvider = .init(authManager: self.authManager, lightroomConnector: self.lightroomConnector)
        self.syncEngine = SyncEngine()
        self.filesystemTargetProvider = .init()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
        }
        .environment(self.authManager)
        .environment(self.lightroomConnector)
        .environment(self.lightroomSourceProvider)
        .environment(self.filesystemTargetProvider)
        .environment(self.syncEngine)
        
#if canImport(WebKit)
        WindowGroup(id: "oauth") {
            OAWebView(oauth: self.authManager.oauth)
        }
#endif
    }
}

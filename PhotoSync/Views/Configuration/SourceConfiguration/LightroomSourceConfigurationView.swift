//
//  LightroomSourceConfigurationView.swift
//  PhotoSync
//
//  Created by Dirk Stichling on 10.03.26.
//

import SwiftUI

struct LightroomSourceConfigurationView: View {
    @Environment(AdobeAuthManager.self) var authManager
    @Environment(LightroomSourceProvider.self) var sourceProvider

    var body: some View {
        if self.authManager.isAuthorized {
        }
        else {
            Button("Sign in to Adobe Lightroom …") {
                self.authManager.authenticate()
            }
        }
    }
}

#Preview {
    LightroomSourceConfigurationView()
}

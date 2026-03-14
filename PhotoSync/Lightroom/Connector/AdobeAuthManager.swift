//
//  AdobeAuthManager.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 30.12.25.
//

import Foundation
import OAuthKit

@MainActor
@Observable
class AdobeAuthManager {
    let oauth: OAuth
    
    var isAuthorized: Bool = false
    var accessToken: String? = nil

    init() {
        let providers: [OAuth.Provider] = [OAuth.Provider(
            id: "adobe",
            authorizationURL: URL(string: "https://ims-na1.adobelogin.com/ims/authorize/v2")!,
            accessTokenURL: URL(string: "https://ims-na1.adobelogin.com/ims/token/v3")!,
            clientID: "fdd1936caa144180876858ef4a39b404",
            clientSecret: nil,
            redirectURI: "adobe+78789e50e5e275dcb231ab6c687948543dca6753://adobeid/fdd1936caa144180876858ef4a39b404",
            scope: ["offline_access","lr_partner_apis","lr_partner_rendition_apis","AdobeID","openid"]
        )]
        let options: [OAuth.Option: Any] = [
            .applicationTag: "info.stichling.PhotoSync",
            .autoRefresh: true,
            .useNonPersistentWebDataStore: false,
        ]
        
        self.oauth = .init(providers: providers, options: options)
        
        self.observeState()
    }
    
    func observeState() {
        withObservationTracking {
            if case .authorized(_, let token) = self.oauth.state {
                self.isAuthorized = true
                self.accessToken = token.token.accessToken
            }
            else {
                self.isAuthorized = false
                self.accessToken = nil
            }
        } onChange: {
            Task { @MainActor in
                self.observeState()
            }
        }
    }
    
    func getAdobeProvider() -> OAuth.Provider? {
        return self.oauth.providers.first { $0.id == "adobe" }
    }
    
    func authenticate() {
        guard let provider = getAdobeProvider() else {
            print("Adobe provider not found")
            return
        }
        
        // Use PKCE flow for secure authentication
        let grantType: OAuth.GrantType = .pkce(.init())
        self.oauth.authorize(provider: provider, grantType: grantType)
    }
    
    func logout() {
        self.oauth.clear()
    }
}

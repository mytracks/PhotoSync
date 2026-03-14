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
    private var authorization: OAuth.Authorization?
    
    private var refreshTimer: Timer?

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
        
        self.startRefreshTimer()
    }
    
    func observeState() {
        withObservationTracking {
            print("observeState: \(self.oauth.state)")
            if case .authorized(_, let authorization) = self.oauth.state {
                print("state: authorized")
                self.isAuthorized = true
                self.accessToken = authorization.token.accessToken
                self.authorization = authorization
            }
            else if case .requestingAccessToken(let provider) = self.oauth.state {
                print("state: requestingAccessToken")
            }
            else if case .error(let provider, let error) = self.oauth.state {
                print("state: error")
            }
            else {
//                self.isAuthorized = false
//                self.accessToken = nil
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
    

    func startRefreshTimer() {
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in
                self.updateAccessTokenIfNeeded()
            }
        }
    }

    func stopRefreshTimer() {
        self.refreshTimer?.invalidate()
        self.refreshTimer = nil
    }
    
    var r = false
    func updateAccessTokenIfNeeded() {
        guard let provider = getAdobeProvider() else {
            print("Adobe provider not found")
            return
        }

        if let authorization, let expiration = authorization.expiration {
            let secondsTilExpiry = expiration.timeIntervalSinceNow
            print("Expires: \(secondsTilExpiry)")
            
            if secondsTilExpiry < 5*60 {
                print("requesting refresh")
                self.oauth.authorize(provider: provider, grantType: .refreshToken)
            }
        }
    }
}

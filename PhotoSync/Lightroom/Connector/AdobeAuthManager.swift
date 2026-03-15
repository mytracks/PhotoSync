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
            clientID: "f8fb3f4f2c4447479a05dd0bb6404287",
            clientSecret: nil,
            redirectURI: "adobe+feb68b1dbf5a8b5ed1d43bb796bc637e4ec2ab02://adobeid/f8fb3f4f2c4447479a05dd0bb6404287",
            scope: ["offline_access","lr_partner_apis","lr_partner_rendition_apis","AdobeID","openid"]
        )]
        
        let options: [OAuth.Option: Any] = [
            .applicationTag: "info.stichling.PhotoSync",
            .autoRefresh: false,
            .useNonPersistentWebDataStore: false,
        ]
        
        self.oauth = .init(providers: providers, options: options)
        
        self.observeState()
    }
    
    func observeState() {
        withObservationTracking {
            print("observeState: \(self.oauth.state)")
            if case .authorized(_, let authorization) = self.oauth.state {
                print("state: authorized")
                self.isAuthorized = !authorization.isExpired
                self.accessToken = authorization.token.accessToken
                self.authorization = authorization
            }
            else if case .authorizing(let provider, let grantType) = self.oauth.state {
                print("state: authorizing for grant type \(grantType) for provider \(provider.id)")
            }
            else if case .requestingDeviceCode(let provider) = self.oauth.state {
                print("state: requestingDeviceCode for provider \(provider.id)")
            }
            else if case .receivedDeviceCode(let provider, let deviceCode) = self.oauth.state {
                print("state: receivedDeviceCode \(deviceCode) for provider \(provider.id)")
            }
            else if case .requestingAccessToken(let provider) = self.oauth.state {
                print("state: requestingAccessToken for provider \(provider.id)")
            }
            else if case .error(let provider, let error) = self.oauth.state {
                print("state: error for provider \(provider.id): \(error.localizedDescription)")
                self.isAuthorized = false
                self.accessToken = nil
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

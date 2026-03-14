//
//  AdobeOAuthService.swift
//  PhotoSync
//

import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct AdobeOAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
    let tokenType: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

enum AdobeOAuthError: Error, LocalizedError {
    case invalidClientID
    case unableToStartSession
    case callbackURLMissing
    case missingAuthorizationCode
    case invalidTokenResponse
    case tokenExchangeFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidClientID:
            return "Please provide your Adobe API Key before signing in."
        case .unableToStartSession:
            return "Unable to start the Adobe sign-in session."
        case .callbackURLMissing:
            return "Adobe sign-in did not return a callback URL."
        case .missingAuthorizationCode:
            return "Adobe sign-in did not return an authorization code."
        case .invalidTokenResponse:
            return "Adobe token exchange returned an invalid response."
        case .tokenExchangeFailed(let statusCode):
            return "Adobe token exchange failed (HTTP \(statusCode))."
        }
    }
}

@MainActor
final class AdobeOAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let session: URLSession
    private var webAuthSession: ASWebAuthenticationSession?

    private let authorizationEndpoint = URL(string: "https://ims-na1.adobelogin.com/ims/authorize/v2")!
    private let tokenEndpoint = URL(string: "https://ims-na1.adobelogin.com/ims/token/v3")!
    private let redirectURI = URL(string: "adobe+78789e50e5e275dcb231ab6c687948543dca6753://adobeid/fdd1936caa144180876858ef4a39b404")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signIn(clientID: String) async throws -> AdobeOAuthTokenResponse {
        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientID.isEmpty else {
            throw AdobeOAuthError.invalidClientID
        }

        let codeVerifier = self.createCodeVerifier()
        let codeChallenge = self.createCodeChallenge(from: codeVerifier)
        let code = try await self.requestAuthorizationCode(
            clientID: trimmedClientID,
            codeChallenge: codeChallenge
        )

        return try await self.exchangeCodeForToken(
            code: code,
            clientID: trimmedClientID,
            codeVerifier: codeVerifier
        )
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if canImport(AppKit)
        return NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
#elseif canImport(UIKit)
        // On iOS, return the key window's scene's window if available
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.keyWindow {
            return window
        }
        // Fallback to a new window if none available
        return UIWindow()
#else
        return ASPresentationAnchor()
#endif
    }

    private func requestAuthorizationCode(clientID: String, codeChallenge: String) async throws -> String {
        var components = URLComponents(url: self.authorizationEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "AdobeID openid lr_partner_apis offline_access"),
            URLQueryItem(name: "redirect_uri", value: self.redirectURI.absoluteString),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let authorizationURL = components?.url else {
            throw AdobeOAuthError.unableToStartSession
        }

        return try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: self.redirectURI.scheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: AdobeOAuthError.callbackURLMissing)
                    return
                }

                let returnedCode = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "code" })?
                    .value

                guard let returnedCode, !returnedCode.isEmpty else {
                    continuation.resume(throwing: AdobeOAuthError.missingAuthorizationCode)
                    return
                }

                continuation.resume(returning: returnedCode)
            }

            authSession.prefersEphemeralWebBrowserSession = false
            authSession.presentationContextProvider = self
            self.webAuthSession = authSession

            guard authSession.start() else {
                self.webAuthSession = nil
                continuation.resume(throwing: AdobeOAuthError.unableToStartSession)
                return
            }
        }
    }

    private func exchangeCodeForToken(
        code: String,
        clientID: String,
        codeVerifier: String
    ) async throws -> AdobeOAuthTokenResponse {
        var request = URLRequest(url: self.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let bodyParams: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": self.redirectURI.absoluteString
        ]
        request.httpBody = self.formURLEncodedData(from: bodyParams)

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdobeOAuthError.invalidTokenResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AdobeOAuthError.tokenExchangeFailed(httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AdobeOAuthTokenResponse.self, from: data)
        } catch {
            throw AdobeOAuthError.invalidTokenResponse
        }
    }

    private func formURLEncodedData(from params: [String: String]) -> Data {
        let query = params
            .map { key, value in
                "\(self.urlEncode(key))=\(self.urlEncode(value))"
            }
            .sorted()
            .joined(separator: "&")
        return Data(query.utf8)
    }

    private func urlEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func createCodeVerifier() -> String {
        let randomData = Data((0..<32).map { _ in UInt8.random(in: 0...UInt8.max) })
        return self.base64URL(randomData)
    }

    private func createCodeChallenge(from verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return self.base64URL(Data(hash))
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

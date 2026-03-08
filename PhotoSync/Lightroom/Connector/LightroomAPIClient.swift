//
//  LightroomAPIClient.swift
//  CreativeCloudApp
//
//  Created by Dirk Stichling on 30.12.25.
//

import Foundation

/// https://developer.adobe.com/lightroom/lightroom-api-docs/api/
class LightroomAPIClient {
    private static let baseURL = "https://lr.adobe.io/v2"
    private static let clientId = "fdd1936caa144180876858ef4a39b404"
    
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    private func makeSingleGetRequest(url: URL, contentType: String? = "application/json") async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.clientId, forHTTPHeaderField: "X-API-Key")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "LightroomAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode)"]
            )
        }
        
        // Some Adobe APIs prefix JSON with a security string like "while (1) {}". Strip it if present.
        let cleanedData: Data
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "while (1) {}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedData = string.data(using: .utf8) ?? data
        } else {
            cleanedData = data
        }
        
        return cleanedData
    }

    private func makeSinglePostRequest(url: URL, body: Data? = nil, additionalHeaders: [String:String]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.clientId, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "LightroomAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode)"]
            )
        }
        
        // Some Adobe APIs prefix JSON with a security string like "while (1) {}". Strip it if present.
        let cleanedData: Data
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "while (1) {}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedData = string.data(using: .utf8) ?? data
        } else {
            cleanedData = data
        }
        
        return cleanedData
    }

    private func loadResources(endpoint: String) async throws -> [[String: Any]] {
        guard let url = URL(string: "\(Self.baseURL)/\(endpoint)") else { return .init() }

        return try await loadResources(url: url)
    }
    
    private func loadResources(url: URL) async throws -> [[String: Any]] {
        var nextURL: URL? = url
        var allResources: [[String: Any]] = []

        while let url = nextURL {
            let data = try await makeSingleGetRequest(url: url)
            nextURL = nil
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let base = json["base"] as? String {
                    if let links = json["links"] as? [String: Any] {
                        if let next = links["next"] as? [String: Any], let nextHref = next["href"] as? String {
                            nextURL = URL(string: "\(base)\(nextHref)")
                        }
                    }
                    
                    if let resources = json["resources"] as? [[String: Any]] {
                        allResources.append(contentsOf: resources)
                    }
                }
            }
        }
        
        return allResources
    }
    
    func getCatalog() async throws -> Catalog? {
        guard let url = URL(string: "\(Self.baseURL)/catalog") else { return nil }
        
        let data = try await makeSingleGetRequest(url: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return Catalog.from(json: json)
    }
    
    func getAlbumAssets(catalogId: String, albumId: String) async throws -> [AlbumAsset] {
        let assets = try await loadResources(endpoint: "catalogs/\(catalogId)/albums/\(albumId)/assets")
        
        return AlbumAsset.list(from: assets, albumId: albumId)
    }
    
    /// Example: Get assets from a catalog
    /// Implement this when you're ready to add functionality
    func getAlbums(catalogId: String) async throws -> [Album] {
        let albums = try await loadResources(endpoint: "catalogs/\(catalogId)/albums")
        
        return Album.list(from: albums)
    }
    
    func getAssets(catalogId: String, assetIds: [String]) async throws -> [Asset] {
        var assets = [Asset]()
        var assetIdsToBeProcessed = assetIds
        
        while assetIdsToBeProcessed.count > 0 {
            let count = min(assetIdsToBeProcessed.count, 100)
            let nextAssetIds = assetIdsToBeProcessed[0..<count]
            assetIdsToBeProcessed = Array(assetIdsToBeProcessed[count...])
            
            let assetIdsString = nextAssetIds.joined(separator: ",")
            assets.append(contentsOf: Asset.list(from:try await loadResources(endpoint: "catalogs/\(catalogId)/assets?asset_ids=\(assetIdsString)")))
        }
        
        return assets
    }
    
    func generateFullsizeRenditions(catalogId: String, assetId: String) async throws {
        guard let url = URL(string: "\(Self.baseURL)/catalogs/\(catalogId)/assets/\(assetId)/renditions") else { return }

        let additionalHeaders: [String: String] = [
            "X-Generate-Renditions": "fullsize"
        ]
        
        _ = try await makeSinglePostRequest(url: url, additionalHeaders: additionalHeaders)
    }
    
    func getFullsizeRendition(catalogId: String, assetId: String) async throws -> Data {
        guard let url = URL(string: "\(Self.baseURL)/catalogs/\(catalogId)/assets/\(assetId)/renditions/fullsize") else { throw LightroomConnectorError.general("invalid URL") }
        
        let response = try await makeSingleGetRequest(url: url, contentType: "image/jpeg")
        
        return response
    }
}

//
//  LightroomCloudService.swift
//  PhotoSync
//

import Foundation

struct LightroomCloudConfiguration {
    let apiKey: String
    let accessToken: String
    let catalogID: String
    let baseURL: URL

    init(apiKey: String, accessToken: String, catalogID: String, baseURL: URL = URL(string: "https://lr.adobe.io")!) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.accessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.catalogID = catalogID.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = baseURL
    }

    var isValid: Bool {
        !self.apiKey.isEmpty && !self.accessToken.isEmpty && !self.catalogID.isEmpty
    }

    var hasCredentials: Bool {
        !self.apiKey.isEmpty && !self.accessToken.isEmpty
    }
}

struct LightroomCloudService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchCatalog(apiKey: String, accessToken: String, baseURL: URL = URL(string: "https://lr.adobe.io")!) async throws -> LightroomCatalog {
        let credentials = LightroomCloudConfiguration(apiKey: apiKey, accessToken: accessToken, catalogID: "_", baseURL: baseURL)

        do {
            let response: LightroomCatalog = try await self.requestWithCredentials(
                credentials,
                path: "/v2/catalog"
            )

            return response
        }
    }

    func fetchFolders(configuration: LightroomCloudConfiguration) async throws -> [LightroomFolder] {
        var fetchedFolders: [LightroomFolder] = []
        var cursor: String?

        repeat {
            let path = "/v2/catalogs/\(configuration.catalogID)/albums"
            let response: LightroomListEnvelope<LightroomFolder> = try await self.request(
                configuration: configuration,
                path: path,
                queryItems: self.queryItems(limit: 200, cursor: cursor)
            )

            fetchedFolders.append(contentsOf: response.items)
            cursor = response.nextCursor
        } while cursor != nil

        return fetchedFolders
    }

    func fetchAssets(folderID: String, configuration: LightroomCloudConfiguration) async throws -> [LightroomAsset] {
        var fetchedAssets: [LightroomAsset] = []
        var cursor: String?

        repeat {
            let path = "/v2/catalogs/\(configuration.catalogID)/albums/\(folderID)/assets"
            let response: LightroomListEnvelope<LightroomAsset> = try await self.request(
                configuration: configuration,
                path: path,
                queryItems: self.queryItems(limit: 200, cursor: cursor)
            )

            fetchedAssets.append(contentsOf: response.items)
            cursor = response.nextCursor
        } while cursor != nil

        return fetchedAssets
    }

    func resolveJPGDownloadURL(assetID: String, configuration: LightroomCloudConfiguration) async throws -> URL {
//        let path = "/v2/catalogs/\(configuration.catalogID)/assets/\(assetID)/renditions"
//        let response: LightroomListEnvelope<LightroomRendition> = try await self.request(
//            configuration: configuration,
//            path: path,
//            queryItems: [
//                URLQueryItem(name: "type", value: "jpg"),
//                URLQueryItem(name: "limit", value: "50")
//            ]
//        )

        let path = "/v2/catalogs/\(configuration.catalogID)/assets/\(assetID)/renditions/fullsize"
      let response: LightroomRendition = try await self.request(
            configuration: configuration,
            path: path
        )
        
        if response.isJPG, let url = response.downloadURL {
            return url
        }

        throw LightroomSyncError.noDownloadURL(assetID: assetID)
    }

    func downloadAsset(from remoteURL: URL, to destinationURL: URL, configuration: LightroomCloudConfiguration) async throws {
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "GET"
        request.addValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LightroomSyncError.invalidResponse
        }

        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw LightroomSyncError.failedToWriteFile(destinationURL, error)
        }
    }
    
    func generateRendition(assetID: String, configuration: LightroomCloudConfiguration) async throws {
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LightroomSyncError.invalidResponse
        }

        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw LightroomSyncError.failedToWriteFile(destinationURL, error)
        }
    }

    private func queryItems(limit: Int, cursor: String?) -> [URLQueryItem] {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return items
    }

    private func request<T: Decodable>(
        configuration: LightroomCloudConfiguration,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard configuration.isValid else {
            throw LightroomSyncError.invalidConfiguration
        }

        var components = URLComponents(
            url: configuration.baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw LightroomSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            throw LightroomSyncError.invalidResponse
        }
        
        // Some Adobe APIs prefix JSON with a security string like "while (1) {}". Strip it if present.
        let cleanedData: Data
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "while (1) {}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedData = string.data(using: .utf8) ?? data
        } else {
            cleanedData = data
        }

        do {
            return try self.decoder.decode(T.self, from: cleanedData)
        } catch {
            throw LightroomSyncError.invalidResponse
        }
    }

    private func requestWithCredentials<T: Decodable>(
        _ configuration: LightroomCloudConfiguration,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard configuration.hasCredentials else {
            throw LightroomSyncError.invalidConfiguration
        }

        var components = URLComponents(
            url: configuration.baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw LightroomSyncError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw LightroomSyncError.invalidResponse
        }

        // Some Adobe APIs prefix JSON with a security string like "while (1) {}". Strip it if present.
        let cleanedData: Data
        if var string = String(data: data, encoding: .utf8) {
            string = string.replacingOccurrences(of: "while (1) {}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            cleanedData = string.data(using: .utf8) ?? data
        } else {
            cleanedData = data
        }

        do {
            return try self.decoder.decode(T.self, from: cleanedData)
        } catch {
            throw LightroomSyncError.invalidResponse
        }
    }
}

private struct LightroomListEnvelope<Item: Decodable>: Decodable {
    let resources: [Item]?
    let data: [Item]?
    let nextCursor: String?
    let cursor: String?

    enum CodingKeys: String, CodingKey {
        case resources
        case data
        case nextCursor = "next_cursor"
        case cursor
    }

    var items: [Item] {
        self.resources ?? self.data ?? []
    }
}

private struct LightroomRendition: Decodable {
    let format: String?
    let downloadURL: URL?

    enum CodingKeys: String, CodingKey {
        case format
        case downloadURL = "download_url"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.format = try container.decodeIfPresent(String.self, forKey: .format)
        self.downloadURL = try container.decodeIfPresent(URL.self, forKey: .downloadURL)
            ?? container.decodeIfPresent(URL.self, forKey: .url)
    }

    var isJPG: Bool {
        guard let format = self.format?.lowercased() else { return false }
        return format == "jpg" || format == "jpeg"
    }
}

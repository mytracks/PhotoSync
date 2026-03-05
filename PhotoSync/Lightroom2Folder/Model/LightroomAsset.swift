//
//  LightroomAsset.swift
//  PhotoSync
//

import Foundation

struct LightroomAsset: Identifiable, Hashable, Decodable {
    let id: String
    let fileName: String
    let downloadURL: URL?

    private enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
        case originalFileName = "original_filename"
        case name
        case downloadURL = "download_url"
        case url
        case links
        case renditions
    }

    private enum LinksKeys: String, CodingKey {
        case download
    }

    private enum DownloadKeys: String, CodingKey {
        case href
    }

    private enum RenditionKeys: String, CodingKey {
        case format
        case downloadURL = "download_url"
        case url
    }

    init(id: String, fileName: String, downloadURL: URL?) {
        self.id = id
        self.fileName = fileName
        self.downloadURL = downloadURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)

        if let fileName = try container.decodeIfPresent(String.self, forKey: .fileName), !fileName.isEmpty {
            self.fileName = fileName
        } else if let original = try container.decodeIfPresent(String.self, forKey: .originalFileName), !original.isEmpty {
            self.fileName = original
        } else if let name = try container.decodeIfPresent(String.self, forKey: .name), !name.isEmpty {
            self.fileName = name
        } else {
            self.fileName = self.id + ".jpg"
        }

        if let direct = try container.decodeIfPresent(URL.self, forKey: .downloadURL) {
            self.downloadURL = direct
            return
        }

        if let plain = try container.decodeIfPresent(URL.self, forKey: .url) {
            self.downloadURL = plain
            return
        }

        if let links = try? container.nestedContainer(keyedBy: LinksKeys.self, forKey: .links),
           let download = try? links.nestedContainer(keyedBy: DownloadKeys.self, forKey: .download),
           let href = try download.decodeIfPresent(URL.self, forKey: .href) {
            self.downloadURL = href
            return
        }

        if var renditions = try? container.nestedUnkeyedContainer(forKey: .renditions) {
            var jpgURL: URL?
            while !renditions.isAtEnd {
                let rendition = try renditions.nestedContainer(keyedBy: RenditionKeys.self)
                let format = (try rendition.decodeIfPresent(String.self, forKey: .format) ?? "").lowercased()
                let candidate = try rendition.decodeIfPresent(URL.self, forKey: .downloadURL)
                    ?? rendition.decodeIfPresent(URL.self, forKey: .url)
                if format == "jpg" || format == "jpeg" {
                    jpgURL = candidate
                    break
                }
                if jpgURL == nil {
                    jpgURL = candidate
                }
            }
            self.downloadURL = jpgURL
            return
        }

        self.downloadURL = nil
    }
}

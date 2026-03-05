//
//  LightroomCatalog.swift
//  PhotoSync
//

import Foundation

struct LightroomCatalog: Identifiable, Hashable, Decodable {
    let id: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        if let title = try container.decodeIfPresent(String.self, forKey: .title), !title.isEmpty {
            self.name = title
        } else if let name = try container.decodeIfPresent(String.self, forKey: .name), !name.isEmpty {
            self.name = name
        } else {
            self.name = self.id
        }
    }
}

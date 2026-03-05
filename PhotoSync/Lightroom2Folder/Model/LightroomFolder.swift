//
//  LightroomFolder.swift
//  PhotoSync
//

import Foundation

struct LightroomFolder: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let parentID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case payload
        case parentID = "parent_id"
        case parent
    }

    private enum PayloadCodingKeys: String, CodingKey {
        case name
        case title
        case parent
    }

    private enum ParentCodingKeys: String, CodingKey {
        case id
    }

    init(id: String, name: String, parentID: String?) {
        self.id = id
        self.name = name
        self.parentID = parentID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)

        let payload = try? container.nestedContainer(keyedBy: PayloadCodingKeys.self, forKey: .payload)

        if let payloadTitle = try payload?.decodeIfPresent(String.self, forKey: .title), !payloadTitle.isEmpty {
            self.name = payloadTitle
        } else if let payloadName = try payload?.decodeIfPresent(String.self, forKey: .name), !payloadName.isEmpty {
            self.name = payloadName
        } else if let title = try container.decodeIfPresent(String.self, forKey: .title), !title.isEmpty {
            self.name = title
        } else if let name = try container.decodeIfPresent(String.self, forKey: .name), !name.isEmpty {
            self.name = name
        } else {
            self.name = self.id
        }

        if let directParentID = try container.decodeIfPresent(String.self, forKey: .parentID) {
            self.parentID = directParentID
        } else if let payloadParent = try? payload?.nestedContainer(keyedBy: ParentCodingKeys.self, forKey: .parent),
                  let payloadParentID = try payloadParent.decodeIfPresent(String.self, forKey: .id) {
            self.parentID = payloadParentID
        } else if let parentContainer = try? container.nestedContainer(keyedBy: ParentCodingKeys.self, forKey: .parent),
                  let nestedParentID = try parentContainer.decodeIfPresent(String.self, forKey: .id) {
            self.parentID = nestedParentID
        } else {
            self.parentID = nil
        }
    }
}

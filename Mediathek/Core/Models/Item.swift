//
//  Item.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

struct Item: Decodable, Encodable, Identifiable, Equatable {
    let urn: String?
    let id: String
    let title: String?
    let subtitle: String?
    let program: Program?
    let description: String?
    let media: [MediaItem]?
    let image: ItemMetadataImage?
    let duration: Int?
    let broadcasts: Double?
    let webpageURL: String?
    let publisher: String?
    let originator: String?
    let captured: Double?
    let downloadAllowed: Bool?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

}

struct ItemMetadataImage: Decodable, Encodable {
    let variants: [ImageVariant]
}

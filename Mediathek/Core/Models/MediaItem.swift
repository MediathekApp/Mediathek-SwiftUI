//
//  MediaItem.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

struct MediaItem: Decodable, Encodable {
    let url: String
    let downloadAllowed: Bool?
}

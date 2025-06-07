//
//  MetadataCache.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

let MetadataCacheMaxAge = Double.greatestFiniteMagnitude

class MetadataCache {

    static let shared = MetadataCache()

    var data: [String: MetadataCacheEntry] = [:]

    func get(urn: String) -> MetadataCacheEntry? {
        return data[urn]
    }

    func set(urn: String, _ value: String, _ date: Date) {
        data[urn] = MetadataCacheEntry(string: value, date: date)
    }

}

struct MetadataCacheEntry {
    var string: String
    var date: Date
}

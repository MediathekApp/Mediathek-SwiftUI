//
//  ExplorePageContents.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

struct ExplorePageContents: Decodable {
    let title: String?
    let items: [Item]
    let categories: [String]?
    let currentCategory: String?
}

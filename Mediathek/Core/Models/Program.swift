//
//  Program.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

struct Program: Decodable, Encodable, Identifiable {
    let urn: String?
    let id: String
    let name: String?
    let items: [Item]?
    let publisher: String?
    let feedCaptured: Double?
    let captured: Double?
    let description: String?
    let homepage: String?
    let image: [ImageVariant]?
}

struct ProgramFeed: Decodable {
    let items: [Item]
}

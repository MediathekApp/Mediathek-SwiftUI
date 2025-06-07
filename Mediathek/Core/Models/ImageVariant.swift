//
//  ImageVariant.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

struct ImageVariant: Decodable, Encodable {
    let url: String
    let width: Int?
    let height: Int?
}

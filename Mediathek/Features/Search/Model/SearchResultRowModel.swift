//
//  SearchResultRowModel.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

class SearchResultRowModel: ObservableObject {
    @Published var searchResult: SerperDevSearchResult?
    @Published var type: SearchResultType = .Item
    @Published var item: Item? = nil

    var urn: String?
    init(searchResult: SerperDevSearchResult? = nil) {
        self.searchResult = searchResult
    }
}

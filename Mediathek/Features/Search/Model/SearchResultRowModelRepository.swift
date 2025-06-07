//
//  SearchResultRowModelRepository.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

class SearchResultRowModelRepository {
    
    static var shared = SearchResultRowModelRepository()
    
    var stores: [String: SearchResultRowModel] = [:]
    
    func get(_ link: String) -> SearchResultRowModel? {
        return stores[link]
    }
    
    func set(_ link: String, _ item: SearchResultRowModel) {
        stores[link] = item
    }
    
    func forSearchResult(_ searchResult: SerperDevSearchResult) -> SearchResultRowModel {
        guard let stored = get(searchResult.link) else {
            let store = SearchResultRowModel(searchResult: searchResult)
            set(searchResult.link, store)
            return store
        }
        return stored
    }

    func forUrn(_ urn: String) -> SearchResultRowModel? {
        return stores.first { (element) in
            element.value.urn == urn
        }?.value
    }

}

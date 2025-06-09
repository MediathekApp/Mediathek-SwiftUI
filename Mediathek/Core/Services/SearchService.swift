//
//  SearchService.swift
//  Mediathek
//
//  Created by Jon on 31.05.25.
//

import Foundation

class SearchService {
    
}

struct Search {
    let query: String
    let response: SerperDevResponse?
}

struct SerperDevResponse: Decodable, Encodable {
    let organic: [SerperDevSearchResult]
    let relatedSearches: [SerperDevRelatedSearch]?
}

struct SerperDevSearchResult: Decodable, Encodable {
    let title: String?
    let link: String
    let snippet: String?
    let date: String?
    let position: Int
}

struct SerperDevRelatedSearch: Decodable, Encodable {
    let query: String
}

enum SearchError: Error {
    case InvalidQuery
    case InvalidAPIKey
}

class SerperDevSearchService: SearchService {
    
    static private var apiKey: String? {
        get {
            return CloudBundle.shared.getConfigString("serperDevAPIKey")
        }
    }
    static private let searchScopeSuffix = "site%3Aardmediathek.de+OR+site%3Azdf.de+OR+site%3Aarte.tv"
    
    func search(query: String, callback: @escaping (Error?, SerperDevResponse?) -> Void) {
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            callback(SearchError.InvalidQuery, nil)
            return
        }
        
        guard let apiKey = SerperDevSearchService.apiKey else {
            callback(SearchError.InvalidAPIKey, nil)
            return
        }
        
        let numberOfResults = 15
        var request = URLRequest(url: URL(string: "https://google.serper.dev/search?q=\(encodedQuery)+\(SerperDevSearchService.searchScopeSuffix)&gl=de&hl=de&num=\(numberOfResults)&apiKey=\(apiKey)")!,timeoutInterval: 5)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
          guard let data = data else {
            print(String(describing: error))
            return
          }
            
            do {
                let decoded = try JSONDecoder().decode(SerperDevResponse.self, from: data)
                DispatchQueue.main.async {
                    callback(nil, decoded)
                }
            } catch {
                log("Failed to decode JSON: \(error)", .error)
            }

        }

        task.resume()
    }
    
}

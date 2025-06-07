//
//  Attention.swift
//  Mediathek
//
//  Created by Jon on 31.05.25.
//

import Foundation


class RecommendationService {
    
    static var shared = RecommendationService()

    private var recommendationServerHost: String? {
        get {
            return CloudBundle.shared.getConfigString("recommendationServer")
        }
    }
    
    public var searchRecommendations: [SearchRecommendation] = []

    func loadSearchRecommendations() {
        
        MetadataStore.shared.request(
            urn: "urn:mediathek:recommendations:queries",
            maxAge: 0,
            strategy: .OnlyCachedElseNilRemoteFirst)
        { jsonString, source, notExpired in
            
            if let jsonString {
                print("Loaded queries: \(jsonString)")
                
                do {
                    let response = try JSONDecoder().decode(
                        SearchRecommendationResponse.self,
                        from: jsonString.data(using: .utf8)!
                    )
                    self.searchRecommendations = response.queries

                } catch {
                    log("Failed to decode JSON: \(error)", .error)
                }

            }
            
        }
        
    }
    
    func track(urnOrQuery: String) {

        guard let host = recommendationServerHost else {
            log("Invalid recommendationServerHost", .error)
            return
        }

        guard let url = URL(string: "https://\(host)/counters") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyData = try? JSONSerialization.data(withJSONObject: ["id": urnOrQuery], options: [])
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("Error sending recommendation data: \(error)", .debug)
                return
            }
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                log("Recommendation data sent successfully", .debug)
            } else {
                log("Failed to send recommendation data", .debug)
            }
        }

        task.resume()
        
    }
    
    func getProgramRecommendationsForNewSubscription(_ subscriptions: [Subscription], callback: ([Program]?) -> Void) {
        
        let urnList = subscriptions.map { sub in
            return sub.urn
        }
        
        guard let host = recommendationServerHost else {
            log("Invalid recommendationServerHost", .error)
            return
        }

        guard let url = URL(string: "https://\(host)/lists") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyData = try? JSONSerialization.data(withJSONObject: ["identifiers":urnList], options: [])
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("Error sending recommendation data: \(error)", .debug)
                return
            }
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                log("Recommendation data sent successfully", .debug)
            } else {
                log("Failed to send recommendation data", .debug)
            }
        }

        task.resume()

        
    }
    
}


struct SearchRecommendation: Decodable {
    let query: String
    let programs: [String]?
}

struct SearchRecommendationResponse: Decodable {
    let queries: [SearchRecommendation]
}


internal func SearchRecommendationFromJSON(_ json: String) -> SearchRecommendation? {
    do {
        let decoded = try JSONDecoder().decode(
            SearchRecommendation.self,
            from: json.data(using: .utf8)!
        )
        return decoded
    } catch {
        log("Failed to decode JSON: \(error)", .error)
    }
    return nil
}


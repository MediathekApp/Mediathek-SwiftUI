//
//  JSON.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

internal func decodeJSON<T: Decodable>(_ json: String, as type: T.Type) -> T? {
    do {
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return decoded
    } catch {
        log("Failed to decode JSON into \(T.self): \(error)", .error)
        return nil
    }
}

internal func encodeToJSON<T: Encodable>(_ value: T) -> String? {
    do {
        let data = try JSONEncoder().encode(value)
        return String(data: data, encoding: .utf8)
    } catch {
        log("Failed to encode \(T.self) to JSON: \(error)", .error)
        return nil
    }
}

//
//  LogMessage.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

enum LogMessageLevel: String, Codable {
    case debug
    case info
    case warning
    case error
}

struct LogMessage: Identifiable, Equatable, Codable {
    var id = UUID()
    let timestamp: Date
    let content: String
    let level: LogMessageLevel

    init(
        id: UUID = UUID(),
        timestamp: Date,
        content: String,
        level: LogMessageLevel
    ) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.level = level
    }

}

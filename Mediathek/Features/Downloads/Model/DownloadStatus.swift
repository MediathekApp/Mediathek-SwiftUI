//
//  DownloadStatus.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

enum DownloadStatus: String {
    case pending
    case downloading
    case paused
    case completed
    case failed
    case canceled
    
    var id: String { self.rawValue }
}

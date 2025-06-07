//
//  DownloadItem.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import Foundation
import SwiftUI

class DownloadItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    @Published var title: String
    @Published var thumbnailURL: URL?
    @Published var progress: Double = 0.0
    @Published var status: DownloadStatus = .pending
    @Published var estimatedTimeRemaining: TimeInterval?
    @Published var errorMessage: String?
    @Published var destinationURL: URL?
    
    // Computed property for the default status message
    var statusText: String {
        switch status {
        case .pending:
            return "Warten …"
        case .downloading:
            if let eta = estimatedTimeRemaining {
                return "Noch \(eta.formattedTime())"
            }
            return String(format: "%.0f%%", progress * 100)
        case .paused:
            return "Angehalten – " + String(format: "%.0f%%", progress * 100)
        case .completed:
            return "Geladen"
        case .failed:
            return "Fehler: \(errorMessage ?? "Unknown error")"
        case .canceled:
            return "Abgebrochen"
        }
    }


    var task: URLSessionDownloadTask? // Assigned by manager
    var resumeData: Data? = nil       // Used for resuming paused downloads
    
    init(url: URL, title: String, thumbnailURL: URL? = nil) {
        self.url = url
        self.title = title
        self.thumbnailURL = thumbnailURL
    }
}

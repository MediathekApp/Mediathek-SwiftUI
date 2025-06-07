//
//  LogManager.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import SwiftUICore
#if (os(macOS))
import AppKit
#endif

class LogManager: ObservableObject {
    
    static let shared = LogManager()

    @Published var messages: [LogMessage] = []

    func append(_ message: String, _ level: LogMessageLevel = .info) {
        DispatchQueue.main.async {
            self.messages.append(
                LogMessage(timestamp: Date(), content: message, level: level)
            )
        }
    }

    
    #if (os(macOS))
    func exportLogsToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "LogExport.json"
        panel.title = "Export Logs"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            do {
                let data = try JSONEncoder().encode(self.messages)
                try data.write(to: url)
            } catch {
                print("Failed to export logs: \(error)")
            }
        }
    }
    #endif

}


// A shortcut to log a message:
func log(_ message: String, _ level: LogMessageLevel = .info) {
    print(message)
    LogManager.shared.append(message, level)
}



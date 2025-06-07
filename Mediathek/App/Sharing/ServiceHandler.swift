//
//  ServiceHandler.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

#if os(macOS)
import AppKit

class ServiceHandler: NSObject {
    @objc func itemsDroppedOnDock(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSError?>?) {
        if let text = pboard.string(forType: .string) {
            print("Received text: \(text)")
            DockState.shared.droppedText = text
            // Handle the received text as needed
        } else {
            print("No text data found on the pasteboard.")
        }
    }
}
#endif

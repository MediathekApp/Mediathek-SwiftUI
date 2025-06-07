//
//  AppDelegate.swift
//  Mediathek
//
//  Created by Jon on 30.05.25.
//

#if os(macOS)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let serviceHandler = ServiceHandler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceHandler
    }
    
}
#endif

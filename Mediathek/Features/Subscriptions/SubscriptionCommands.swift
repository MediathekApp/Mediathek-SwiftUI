//
//  SubscriptionCommands.swift
//  Mediathek
//
//  Created by Jon on 10.06.25.
//

import SwiftUI
import SwiftData

struct SubscriptionCommands: Commands {
    @StateObject private var navManager: NavigationManager = NavigationManager.shared
    var body: some Commands {
        CommandMenu("Abonnement") {
            Button("Alle als gesehen markieren") {
                if let subscription = navManager.currentEntry?.state.subscription {
                    SubscriptionManager.shared.markAllSeen(subscription)
                }
            }
            .keyboardShortcut("k", modifiers: [.command])
            .disabled(navManager.currentEntry?.state.subscription == nil)
        }
    }
}

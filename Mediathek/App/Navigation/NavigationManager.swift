//
//  NavigationManager.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUICore

class NavigationManager: ObservableObject {
    
    static let shared = NavigationManager()
    
    @Published var currentEntry: NavigationEntry?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false

    private var backStack: [NavigationEntry] = []
    private var forwardStack: [NavigationEntry] = []

    func go(to entry: NavigationEntry) {
        if let current = currentEntry {
            backStack.append(current)
        }
        currentEntry = entry
        forwardStack.removeAll()
        updateStates()
    }
    
    func replace(to entry: NavigationEntry) {
        currentEntry = entry
        updateStates()
    }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        if let current = currentEntry {
            forwardStack.append(current)
        }
        currentEntry = previous
        updateStates()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        if let current = currentEntry {
            backStack.append(current)
        }
        currentEntry = next
        updateStates()
    }
    
    internal func updateStates() {
        canGoBack = !backStack.isEmpty
        canGoForward = !forwardStack.isEmpty
    }
}

@ViewBuilder
func view(for entry: NavigationEntry) -> some View {
    switch entry.viewType {
    case .Explore:
        ExplorePageView(state: entry.state)
    case .Program:
        ProgramView(state: entry.state)
    case .Item:
        ItemDetailView(state: entry.state)
    case .Search:
        SearchResultsView(state: entry.state)
    }
}

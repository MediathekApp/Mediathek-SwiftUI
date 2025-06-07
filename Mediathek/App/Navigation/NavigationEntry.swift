//
//  NavigationEntry.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation
import SwiftUICore

struct NavigationEntry: Identifiable, Equatable {
    let id = UUID()
    let viewType: ViewType
    let state: NavigationEntryState
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

}

class NavigationEntryState: ObservableObject {
    var scrollOffset: CGFloat? = nil
    var scrollItemPosition: UnitPoint? = nil
    @Published var item: Item? = nil
    @Published var program: Program? = nil
    @Published var search: Search? = nil
    @Published var explorePage: ExploreViewModel? = nil
    @Published var subscription: Subscription? = nil
}


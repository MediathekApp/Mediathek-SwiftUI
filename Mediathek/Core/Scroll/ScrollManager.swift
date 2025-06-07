//
//  ScrollManager.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

class ScrollOffsetStore: ObservableObject {
    @Published var xOffset: CGFloat? {
        didSet { offsetXDidChange() }
    }
    @Published var yOffset: CGFloat? {
        didSet { offsetYDidChange() }
    }
    func offsetXDidChange() {}
    func offsetYDidChange() {}

    var animationDuration: TimeInterval = 0
}


class ContentViewScrollOffsetStore: ScrollOffsetStore {

    override func offsetYDidChange() {
        let value = yOffset
        //        print("- yOffset changed: \(value != nil ? (value)!.description : "nil")")
        NavigationManager.shared.currentEntry?.state.scrollOffset = value
    }

}

//
//  SubscriptionsViewScrollStore.swift
//  Mediathek
//
//  Created by Jon on 10.06.25.
//

import Combine
import Foundation

class SubscriptionsViewScrollStore: ScrollOffsetStore {

    static var shared = SubscriptionsViewScrollStore()
    private var cancellables = Set<AnyCancellable>()

    var subscriptions: [Subscription] = [] {
        didSet {

            cancellables.removeAll()

            // Observe navigation, scroll to a subscription icon if it is visible:
            NavigationManager.shared.$currentEntry
                .sink { entry in
                    if let entry {
                        if entry.viewType == .Program {
                            if let urn = entry.state.program?.urn {

                                let subscription = self.subscriptions.first {
                                    sub in
                                    return sub.urn == urn
                                }

                                if let subscription {
                                    let index = self.subscriptions.firstIndex {
                                        el in
                                        return el.urn == subscription.urn
                                    }

                                    if let index {
                                        self.animationDuration =
                                            0.4
                                        self.xOffset =
                                            self
                                            .calculateScrollOffsetXForSubscription(
                                                at: index
                                            )
                                    }
                                }

                            }
                        }
                    }

                }
                .store(in: &cancellables)

        }
    }

    // override func offsetXDidChange() {}

    var scrollViewWidth: CGFloat = 0

    internal func calculateScrollOffsetXForSubscription(at index: Int)
        -> CGFloat
    {
        let leftPadding = 10.0
        let itemWidth = AppConfig.subscriptionItemWidth
        let x =
            leftPadding + CGFloat(index) * itemWidth - scrollViewWidth / 2
            + itemWidth / 2
        let itemCount = subscriptions.count
        let contentWidth = leftPadding * 2 + itemWidth * Double(itemCount)
        return min(max(x, 0), contentWidth - scrollViewWidth)
    }

}

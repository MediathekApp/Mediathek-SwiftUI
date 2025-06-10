//
//  SubscriptionItemRow.swift
//  Mediathek
//
//  Created by Jon on 09.06.25.
//

import SwiftUI
import SwiftData

struct SubscriptionItemRow: View {
    
    var item: Item
    var subscription: Subscription
    
    @Bindable var state: SubscriptionItemUserState
    
    var body: some View {
        let isSeen = state.isSeen
        ItemRow(item: item, subscription: subscription, showUnseenIndicator: isSeen != true, showsSource: false)
    }
    
    init(item: Item, subscription: Subscription) {
        self.item = item
        self.subscription = subscription
        self.state = SubscriptionManager.shared.pooledItemState(for: item.id, subscription: subscription)
    }


}

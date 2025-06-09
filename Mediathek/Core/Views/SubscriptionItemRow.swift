//
//  SubscriptionItemRow.swift
//  Mediathek
//
//  Created by Jon on 09.06.25.
//

import SwiftUICore
import SwiftData

struct SubscriptionItemRow: View {
    
    @Environment(\.modelContext) var modelContext

    var item: Item
    var subscription: Subscription
    
    @Bindable var state: SubscriptionItemUserState
    
    var body: some View {
        let isSeen = state.isSeen
        ItemRow(item: item, subscription: subscription, showUnseenIndicator: isSeen != true, showsSource: false)
    }
    
    init(item: Item, subscription: Subscription, modelContext: ModelContext) {
        self.item = item
        self.subscription = subscription
        self.state = SubscriptionManager.shared.pooledItemState(for: item.id, subscription: subscription, modelContext: modelContext)
    }


}

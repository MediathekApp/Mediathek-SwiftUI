//
//  Subscription.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftData
import Foundation

@Model
class Subscription: Identifiable {
    var id: UUID
    var name: String
    var urn: String
    var addedDate: Date
    var imageURL: String?
    var unseenCount: Int?

    init(name: String, urn: String, imageURL: String?) {
        self.id = UUID()
        self.name = name
        self.urn = urn
        self.imageURL = imageURL
        self.addedDate = Date()
        self.unseenCount = 0
    }
    
    @Relationship(deleteRule: .cascade, inverse: \SubscriptionItemUserState.subscription)
    var itemStates: [SubscriptionItemUserState] = []
    
    func updateUnseenCount() {
        unseenCount = itemStates.filter { !$0.isSeen }.count
    }

}

@Model
class SubscriptionItemUserState {
    @Attribute(.unique) var id: String // unique GUID or permalink from feed
    var isSeen: Bool = false
    var seenAt: Date?
    
    @Relationship var subscription: Subscription?

    init(id: String, isSeen: Bool, seenAt: Date? = nil, subscription: Subscription) {
        self.id = id
        self.isSeen = isSeen
        self.seenAt = seenAt
        self.subscription = subscription
    }
}

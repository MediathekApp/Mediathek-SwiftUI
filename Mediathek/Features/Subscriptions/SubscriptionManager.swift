//
//  SubscriptionManager.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

class SubscriptionManager {

    static var shared = SubscriptionManager()

    let autorefreshInterval: TimeInterval = 60 * 60

    func refresh(
        _ sub: Subscription,
        modelContext: ModelContext,
        maxAge: TimeInterval = 0
    ) {

        MetadataStore.shared.requestProgramWithItems(
            urn: sub.urn,
            maxAge: maxAge
        ) { program, source in

            if let program {
                self.updateUnseenCount(
                    subscription: sub,
                    program: program,
                    modelContext: modelContext
                )
                if let programURN = program.urn {
                    self.updateSubscriptionView(programURN: programURN, subscription: sub, modelContext: modelContext)
                }
            }

        }

    }

    func refreshAllSubscriptions(
        modelContext: ModelContext,
        maxAge: TimeInterval = 60 * 30
    ) {

        do {
            let fetchDescriptor = FetchDescriptor<Subscription>()
            let subscriptions = try modelContext.fetch(fetchDescriptor)

            for sub in subscriptions {
                refresh(sub, modelContext: modelContext, maxAge: maxAge)
            }

        } catch {
            log("Failed to fetch subscriptions: \(error)")
        }

    }

    private var timer: AnyCancellable?

    func scheduleAutoRefresh(
        modelContext: ModelContext,
        runInitially: Bool = false
    ) {

        func performOperation() {
            refreshAllSubscriptions(modelContext: modelContext)
        }

        // Only start if the timer isn't already running
        guard timer == nil else { return }

        if runInitially { performOperation() }

        timer = Timer.publish(
            every: autorefreshInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { _ in
            performOperation()
        }

    }

    func stopAutoRefresh() {
        timer?.cancel()
        timer = nil
    }
    
    func trySave(_ modelContext: ModelContext) {
        do {
            try modelContext.save()
        } catch {
            log("Failed to save: \(error)", .error)
        }
    }

    func unsubscribe(
        _ sub: Subscription,
        modelContext: ModelContext /*, animated: Bool = true*/
    ) {

        let subscriptionURN = sub.urn

        modelContext.delete(sub)
        trySave(modelContext)
        
        itemStatePool.drain()
        
        self.updateSubscriptionView(programURN: subscriptionURN, subscription: nil, modelContext: modelContext)
 
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            let remaining = self.getSubscriptions(modelContext)
            if remaining?.isEmpty == true {
                withAnimation {
                    ContentViewModel.shared.showSubscriptions = false
                }
            }
        }

    }
    
    func updateSubscriptionView(programURN: String, subscription: Subscription?, modelContext: ModelContext) {
                
        if let shownProgram = NavigationManager.shared.currentEntry?.state.program {
            if shownProgram.urn == programURN {
                let state = NavigationEntryState()
                state.program = shownProgram
                state.subscription = subscription
                NavigationManager.shared.replace(
                    to: NavigationEntry(
                        viewType: .Program,
                        state: state
                    )
                )
            }
        }

    }

    func subscriptionByURN(_ urn: String, modelContext: ModelContext)
        -> Subscription?
    {

        do {
            let existingSubscriptions = try modelContext.fetch(
                FetchDescriptor<Subscription>(
                    predicate: #Predicate { $0.urn == urn }
                )
            )
            if !existingSubscriptions.isEmpty {
                return existingSubscriptions.first
            }
        } catch {
            log("Can't look for subscriptions: \(error)")
        }
        return nil

    }

    let itemStatePool = ModelPool<SubscriptionItemUserState>()
    
    func pooledItemState(for itemID: String, subscription: Subscription, modelContext: ModelContext) -> SubscriptionItemUserState {
        
        if let pooled = itemStatePool.instance(forID: itemID) {
            return pooled
        }

        if let existing = try? modelContext.fetch(
            FetchDescriptor<SubscriptionItemUserState>(
                predicate: #Predicate { $0.id == itemID }
            )
        ).first {
            
            return itemStatePool.pooledInstance(for: existing)

        } else {

            // Create a new state:
            let newState = SubscriptionItemUserState(
                id: itemID,
                isSeen: false,
                seenAt: Date.now,
                subscription: subscription
            )
            modelContext.insert(newState)
            
            return itemStatePool.pooledInstance(for: newState)

        }
        
    }
    
    func itemStatesForProgram(
        _ program: Program,
        subscription: Subscription,
        modelContext: ModelContext
    ) -> [SubscriptionItemUserState] {

        do {
            if let itemIDs: [String] = program.items?.map({ item in
                item.id
            }) {
                let subscriptionID: UUID = subscription.id
                let predicate = #Predicate<SubscriptionItemUserState> { state in
                    state.subscription?.id == subscriptionID
                        && itemIDs.contains(state.id)
                }

                let matchingStates = try modelContext.fetch(
                    FetchDescriptor(predicate: predicate)
                )
                
                var pooledStates: [SubscriptionItemUserState] = []
                for state in matchingStates {
                    pooledStates.append(itemStatePool.pooledInstance(for: state))
                }
                return pooledStates
            }

        } catch {
            log("Can't look for subscriptions: \(error)")
        }
        return []

    }

    func subscribe(
        _ program: Program,
        modelContext: ModelContext /*, animated: Bool = true*/
    ) {

        if let urn = program.urn {

            // Avoid duplicates:
            if subscriptionByURN(urn, modelContext: modelContext) != nil {
                log("Subscription already exists for \(urn)", .warning)
                return
            }

            let newSub = Subscription(
                name: program.name ?? "?",
                urn: urn,
                imageURL: ProgramFindBestImage(
                    program,
                    desiredAspectRatio: 1.0
                )?.url
            )

            modelContext.insert(newSub)
            trySave(modelContext)

            if let subscriptions = getSubscriptions(modelContext) {
                RecommendationService.shared
                    .getProgramRecommendationsForNewSubscription(subscriptions)
                { programs in
                    // TODO: present recommendations
                }
            }

            withAnimation {
                ContentViewModel.shared.showSubscriptions = true
            }

            // Refresh with a small delay for a smooth animation:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.refresh(newSub, modelContext: modelContext)
            }

        }

    }

    func getSubscriptions(_ modelContext: ModelContext) -> [Subscription]? {

        do {
            let fetchDescriptor = FetchDescriptor<Subscription>()
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            log("Failed to get subscriptions: \(error)")
            return nil
        }

    }

    func markSeen(
        item: Item,
        subscription: Subscription,
        program: Program,
        modelContext: ModelContext,
        seen: Bool = true,
        andSave: Bool = true,
        andUpdateUnseenCount: Bool = true
    ) {

        // Upsert the item state:
        let itemState = pooledItemState(for: item.id, subscription: subscription, modelContext: modelContext)
        itemState.isSeen = seen
        itemState.seenAt = Date.now
        itemState.subscription = subscription
        
        if andSave {
            trySave(modelContext)
        }

        if andUpdateUnseenCount {
            updateUnseenCount(
                subscription: subscription,
                program: program,
                modelContext: modelContext
            )
        }

    }

    func updateUnseenCount(
        subscription: Subscription,
        program: Program,
        modelContext: ModelContext
    ) {

        let itemStates = SubscriptionManager.shared.itemStatesForProgram(
            program,
            subscription: subscription,
            modelContext: modelContext
        )

        var count = program.items?.count ?? 0
        for state in itemStates {
            if state.isSeen {
                count -= 1
            }
        }

        withAnimation {
            subscription.unseenCount = count
            trySave(modelContext)
        }

    }

    func markAllSeen(
        _ subscription: Subscription,
        modelContext: ModelContext,
        seen: Bool = true
    ) {
        
        MetadataStore.shared.requestProgramWithItems(urn: subscription.urn) { program, source in
            
            if let program, let items = program.items, let programURN = program.urn {
                
                for item in items {
                    self.markSeen(item: item, subscription: subscription, program: program, modelContext: modelContext, andUpdateUnseenCount: false)
                }
                
                self.updateUnseenCount(
                    subscription: subscription,
                    program: program,
                    modelContext: modelContext
                )
                
                self.updateSubscriptionView(programURN: programURN, subscription: subscription, modelContext: modelContext)

            }
            
        }
        
    }
    
}

final class ModelPool<T: PersistentModel & Identifiable> {
    private var byPersistentID: [PersistentIdentifier: T] = [:]
    private var byStringID: [String: PersistentIdentifier] = [:]

    func pooledInstance(for model: T) -> T {
        let pid = model.persistentModelID
        let sid = model.id as? String
        
        if let existing = byPersistentID[pid] {
            return existing
        }

        byPersistentID[pid] = model
        if let sid {
            byStringID[sid] = pid
        }
        return model
    }

    func instance(forID stringID: String) -> T? {
        guard let pid = byStringID[stringID] else { return nil }
        return byPersistentID[pid]
    }

    func update(with model: T) {
        let pid = model.persistentModelID
        let sid = model.id as? String

        byPersistentID[pid] = model
        if let sid {
            byStringID[sid] = pid
        }
    }

    func drain() {
        byPersistentID.removeAll()
        byStringID.removeAll()
    }
}

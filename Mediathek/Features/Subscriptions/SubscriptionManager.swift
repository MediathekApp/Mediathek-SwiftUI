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

            //            if source == .LocalCache { return } // no update

            if let program {
                self.updateUnseenCount(
                    subscription: sub,
                    program: program,
                    modelContext: modelContext
                )
            }

            if let urn = NavigationManager.shared.currentEntry?.state.program?
                .urn
            {
                if urn == sub.urn {
                    let state = NavigationEntryState()
                    state.program = program
                    state.subscription = sub
                    NavigationManager.shared.replace(
                        to: NavigationEntry(
                            viewType: .Program,
                            state: state
                        )
                    )
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

    func remove(
        _ sub: Subscription,
        modelContext: ModelContext /*, animated: Bool = true*/
    ) {

        let subscriptionURN = sub.urn

        modelContext.delete(sub)

        if let program = NavigationManager.shared.currentEntry?.state.program {
            if program.urn == subscriptionURN {
                let state = NavigationEntryState()
                state.program = program
                state.subscription = nil
                NavigationManager.shared.replace(
                    to: NavigationEntry(
                        viewType: .Program,
                        state: state
                    )
                )
            }
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            let remaining = self.getSubscriptions(modelContext)
            if remaining?.isEmpty == true {
                withAnimation {
                    ContentViewModel.shared.showSubscriptions = false
                }
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

    func itemStatesForProgram(
        _ program: Program,
        subscription: Subscription,
        modelContext: ModelContext
    ) -> [SubscriptionItemUserState] {

        do {
            //            let itemStatesFetch = FetchDescriptor<SubscriptionItemUserState>(
            //                predicate: #Predicate {
            //                    $0.subscription.id == subscription.id
            //                },
            //                //sortBy: [SortDescriptor(\.seenAt)]
            //            )
            //            let itemStates = try modelContext.fetch(itemStatesFetch)
            //            return itemStates

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
                return matchingStates
            }

        } catch {
            log("Can't look for subscriptions: \(error)")
        }
        return []

    }

    func add(
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
        seen: Bool = true
    ) {

        // Upsert the item state:
        if let existing = try? modelContext.fetch(
            FetchDescriptor<SubscriptionItemUserState>(
                predicate: #Predicate { $0.id == item.id }
            )
        ).first {

            // Update the existing state:
            existing.isSeen = seen
            existing.seenAt = Date.now
            existing.subscription = subscription

        } else {

            // Create a new state:
            let newState = SubscriptionItemUserState(
                id: item.id,
                isSeen: seen,
                seenAt: Date.now,
                subscription: subscription
            )
            modelContext.insert(newState)

        }

        updateUnseenCount(
            subscription: subscription,
            program: program,
            modelContext: modelContext
        )

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
        }

    }

    func markAllSeen(
        subscription: Subscription,
        program: Program,
        modelContext: ModelContext,
        seen: Bool = true
    ) {
        log("Not implemented yet", .warning)
    }

}

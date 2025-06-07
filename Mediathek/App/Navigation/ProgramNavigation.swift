//
//  ProgramNavigation.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftData
import Foundation

func GoToProgram(
    _ urn: String,
    maxAge: TimeInterval = MetadataCacheMaxAge,
    modelContext: ModelContext
) {
    
    MetadataStore.shared.requestProgramWithItems(
        urn: urn,
        maxAge: maxAge
    ) { program, source in
        
        if let program {
            
            let state = NavigationEntryState()
            state.program = program

            // See if there is an active subscription for this program:
            let subscription: Subscription? = SubscriptionManager.shared.subscriptionByURN(urn, modelContext: modelContext)
            if let subscription {
                state.subscription = subscription
            }
            
            NavigationManager.shared.go(
                to: NavigationEntry(
                    viewType: .Program,
                    state: state
                )
            )
            
        }

    }

}

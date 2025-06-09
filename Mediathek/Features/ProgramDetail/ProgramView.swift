//
//  ProgramView.swift
//  Mediathek
//
//  Created by Jon on 30.05.25.
//

import SwiftUI
import SwiftData

struct ProgramView: View {

    var state: NavigationEntryState
        
    @Environment(\.modelContext) private var modelContext

    var body: some View {

        if let program = state.program {

            VStack(alignment: .leading) {

                HStack(alignment: .center, spacing: 12) {
                    
                    Text(program.name ?? "?")
                        .font(.system(size: 23, weight: .medium))
                        .opacity(0.8)
                    
                    Spacer()
                    
                    let hasSubscription = state.subscription != nil
                    Button(hasSubscription ? "Abo beenden" : "Abonnieren") {
                        
                        withAnimation {
                            if let subscription = state.subscription {
                                SubscriptionManager.shared.unsubscribe(subscription, modelContext: modelContext)
                            } else {
                                SubscriptionManager.shared.subscribe(
                                    program,
                                    modelContext: modelContext
                                )
                            }
                        }
                        
                    }

                }

                // Stretch to full width
                Spacer().frame(maxWidth: .infinity)

                if let items = program.items {

                    LazyVStack(alignment: .leading, spacing: 8) {

                        Section {

                            ForEach(items, id: \.id) { item in

                                if let subscription = state.subscription {
                                    SubscriptionItemRow(
                                        item: item,
                                        subscription: subscription,
                                        modelContext: modelContext
                                    )
                                    .padding(.vertical, 4)
                                    .id("sub-"+(item.id))
                                }
                                else {
                                    ItemRow(
                                        item: item,
                                        showUnseenIndicator: false,
                                        showsSource: false,
                                    )
                                    .padding(.vertical, 4)
                                    .id(item.id)
                                }

                            }
                        }

                    }

                } else {
                    Text("Keine Elemente")
                }
                
                #if DEBUG
                Text(program.urn ?? "")
                    .textSelection(.enabled)
                    .opacity(0.2)
                #endif

            }
            .padding(.horizontal, 16 + 8)
            .padding(.vertical, 16)
            .frame(maxWidth: 800, alignment: .leading)

        }

    }
    
    
}

//#Preview {
//    ProgramView()
//}

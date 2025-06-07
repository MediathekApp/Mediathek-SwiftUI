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
    @State private var itemStates: [SubscriptionItemUserState] = []
    
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
                                SubscriptionManager.shared.remove(subscription, modelContext: modelContext)
                            } else {
                                SubscriptionManager.shared.add(
                                    program,
                                    modelContext: modelContext
                                )
                            }
                        }
                        
                    }

                }

                Spacer()

                //            Text("Items: \(program.items?.count ?? 0)").opacity(0.25)

                // Stretch to full width
                Spacer().frame(maxWidth: .infinity)

                if let items = program.items {

                    LazyVStack(alignment: .leading, spacing: 8) {

                        Section {

                            ForEach(items, id: \.id) { item in

                                ItemRow(
                                    item: item,
                                    showUnseenIndicator: isItemUnseen(item),
                                    showsSource: false
                                )
                                .padding(.vertical, 4)
                                .id(item.urn)

                            }
                        }
                        //                    header: {
                        //
                        //                        Text("Beiträge")
                        //                            .font(.title2)
                        //                            .fontWeight(.medium)
                        //                            .foregroundColor(.gray)
                        //
                        //                    }

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
            .onAppear() {
                loadItemStates(modelContext: modelContext)
            }
            .onChange(of: state.subscription) { oldValue, newValue in
                loadItemStates(modelContext: modelContext)
            }

        }

    }
    
    func loadItemStates(modelContext: ModelContext) {
        if let program = state.program, let subscription = state.subscription {
            itemStates = SubscriptionManager.shared.itemStatesForProgram(program, subscription: subscription, modelContext: modelContext)
        }
    }
    
    func isItemUnseen(_ item: Item) -> Bool {
        if state.subscription != nil {
            let state = itemStates.first { state in state.id == item.id }
            return state?.isSeen != true
        }
        return false
    }
    
}

//#Preview {
//    ProgramView()
//}

//
//  SubscriptionsView.swift
//  Mediathek
//
//  Created by Jon on 01.06.25.
//

import SwiftUI
import SwiftData

enum SubscriptionsFilter: String {
    case All = "All"
    case Unseen = "Unseen"
}

struct SubscriptionsView: View {

    private let badgeBackgroundColor: Color = AppConfig.unseenColor
    private let badgeTextColor: Color = Color.white
    private let numberBadgeRelativeOffsetX: CGFloat = 0
    private let numberBadgeRelativeOffsetY: CGFloat = +3

    @State private var scrollStore = SubscriptionsViewScrollStore.shared  // not observed
    @StateObject private var navManager = NavigationManager.shared

    @Environment(\.colorScheme) var colorScheme

    @Query(sort: \Subscription.name, order: .forward) var allSubscriptions: [Subscription]
    
    @Query(filter: #Predicate<Subscription> { ($0.unseenCount ?? 0) > 0 },
           sort: \Subscription.name,
           order: .forward) var subscriptionsWithUnseenItems: [Subscription]

    @AppStorage("visibleSubscriptionsFilter")
    private var filterSelection: SubscriptionsFilter = .All
    
    var subscriptions: [Subscription] {
        filterSelection == .Unseen ? subscriptionsWithUnseenItems : allSubscriptions
    }
    

    internal func loadSubscription(_ subscription: Subscription) {
        // A fast UI response here is important, we always use the cache:
        GoToProgram(subscription.urn, maxAge: MetadataCacheMaxAge)
    }

    
    var body: some View {

        ZStack {
            
            ScrollView(.horizontal) {
                
                LazyHStack(spacing: 0) {
                    
                    ForEach(self.subscriptions, id: \.urn) { subscription in
                        
                        VStack(spacing: 6) {
                            ZStack {
                                SubscriptionIconView(subscription: subscription)
                                
                                if let unseenCount = subscription.unseenCount, unseenCount > 0 {
                                    NumberBadge(
                                        value: unseenCount,
                                        fontSize: 12,
                                        backgroundColor: badgeBackgroundColor,
                                        contentColor: badgeTextColor
                                    )
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: unseenCount)
                                    .offset(x: AppConfig.iconSize/2 + numberBadgeRelativeOffsetX,
                                            y: -AppConfig.iconSize/2 + numberBadgeRelativeOffsetY)
                                    .shadow(
                                        color: Color.black.opacity(0.1),
                                        radius: 2,
                                        x: 0,
                                        y: 2
                                    )
                                }
                            }
                            SubscriptionIconText(subscription: subscription)
                        }
                        .id(subscription.urn)
                        .frame(width: AppConfig.subscriptionItemWidth)
                        .offset(y: 3+12)
                        .contentShape(Rectangle())
                        .transition(
                            .opacity
//                            .asymmetric(
//                                insertion: .fallDownZ,
//                                removal: .scale
//                            )
                        )
                        .onTapGesture {
                            loadSubscription(subscription)
                        }
                        .contextMenu {
                            Button("Aktualisieren") {
                                SubscriptionManager.shared.refresh(subscription)
                            }
                            Button("Alle als gesehen markieren") {
                                SubscriptionManager.shared.markAllSeen(subscription)
                            }
                            Button("Entfernen") {
                                SubscriptionManager.shared.unsubscribe(
                                    subscription
                                )
                            }
                        }
                        
                    }
                }
                .animation(
                    .easeOut(duration: 0.3),//.delay(0.5),
                    value: self.subscriptions
                )
                //                .animation(nil, value: self.subscriptions)
                .padding(.horizontal, 8)
                .frame(height: AppConfig.subscriptionsDockHeight)
#if os(macOS)
                .overlay {
                    ScrollOffsetCoordinator(
                        scrollOffsetStore: scrollStore
                    ).frame(width: 0, height: 0)
                }
#endif
                
            }
            
            VStack {
                HStack {
                    Spacer()

                    Picker("", selection: $filterSelection) {
                        Text("neu").tag(SubscriptionsFilter.Unseen)
                        Text("alle").tag(SubscriptionsFilter.All)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 70)
                    .offset(x: -8, y: 8)
//                    .onChange(of: filterSelection) { oldValue, newValue in
//                        self.showOnlyNew = newValue == SubscriptionsFilter.Unseen
//                    }
                }
                
                Spacer()
            }
            
            if subscriptions.isEmpty {
                Text(filterSelection == SubscriptionsFilter.All ? "Keine Abonnements" : "Keine ungesehenen Beiträge")
                    .fontWeight(.medium)
                    .opacity(0.25)
            }
            
        }
        .background(
            (AppConfig.useBrightSubscriptionsBackground && colorScheme == .light)
                ? Color(white: 0.96, opacity: 0.5)
                : Color(white: 0.10, opacity: 0.5)
        )

        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        scrollStore.scrollViewWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size) { oldSize, newSize in
                        scrollStore.scrollViewWidth = newSize.width
                    }
            }
        )
        .onAppear {
            scrollStore.subscriptions = subscriptions
        }
        .onChange(of: subscriptions) { oldValue, newValue in
            scrollStore.subscriptions = newValue
        }

    }

}

extension AnyTransition {
    static var fallDownY: AnyTransition {
        AnyTransition
            .move(edge: .top)
            .combined(with: .opacity)
    }
    static var fallDownZ: AnyTransition {
        AnyTransition
            .scale(scale: 1.2)
            .combined(with: .opacity)
    }
}

//
//  SubscriptionsView.swift
//  Mediathek
//
//  Created by Jon on 01.06.25.
//

import Combine
import SDWebImageSwiftUI
import SwiftData
import SwiftUI

internal let iconSize: CGFloat = 48
internal let badgeBackgroundColor: Color = AppConfig.unseenColor
internal let badgeTextColor: Color = Color.white
internal let numberBadgeRelativeOffsetX: CGFloat = 0
internal let numberBadgeRelativeOffsetY: CGFloat = +3


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
        let itemWidth = 80.0
        let x =
            leftPadding + CGFloat(index) * itemWidth - scrollViewWidth / 2
            + itemWidth / 2
        let itemCount = subscriptions.count
        let contentWidth = leftPadding * 2 + itemWidth * Double(itemCount)
        return min(max(x, 0), contentWidth - scrollViewWidth)
    }

}

struct SubscriptionsView: View {

    @State private var scrollStore = SubscriptionsViewScrollStore.shared  // not observed
    @StateObject private var navManager = NavigationManager.shared

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.addedDate, order: .forward) var subscriptions:
        [Subscription]
    
    internal func loadSubscription(_ subscription: Subscription) {
        // A fast UI response here is important, we always use the cache:
        ContentView.loadProgram(
            subscription.urn,
            maxAge: MetadataCacheMaxAge,
            modelContext: modelContext
        )
    }

    var body: some View {

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
                                .offset(x: iconSize/2 + numberBadgeRelativeOffsetX,
                                        y: -iconSize/2 + numberBadgeRelativeOffsetY)
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
                    .frame(width: 80)
                    .offset(y: 3)
                    .contentShape(Rectangle())
                    .transition(
                        .asymmetric(
                            insertion: .fallDownZ,
                            removal: .scale
                        )
                    )
                    .onTapGesture {
                        loadSubscription(subscription)
                    }
                    .contextMenu {
                        Button("Aktualisieren") {
                            SubscriptionManager.shared.refresh(subscription, modelContext: modelContext)
                        }
                        Button("Alle als gesehen markieren") {
                            SubscriptionManager.shared.markAllSeen(subscription, modelContext: modelContext)
                        }
                        Button("Entfernen") {
                            SubscriptionManager.shared.unsubscribe(
                                subscription,
                                modelContext: modelContext
                            )
                        }
                    }

                }
            }
            .animation(
                .easeOut(duration: 0.3).delay(0.5),
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
        .background(
            (AppConfig.useBrightSubscriptionsBackground && colorScheme == .light)
                ? Color(white: 0.96, opacity: 0.5)
                : Color(white: 0.12, opacity: 0.5)
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

struct SubscriptionIconView: View {

    //@StateObject
    var subscription: Subscription

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {

        ZStack {

            if let url = subscription.imageURL {
                WebImage(url: URL(string: url)!)
                    .interpolation(.high)
                    .resizable()
                    .scaledToFill()
                    .transition(.fade(duration: 0.5))
                    .frame(width: iconSize, height: iconSize)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: iconSize, height: iconSize)
            }

            // Gradient overlay
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2), Color.white.opacity(0.0),
                        ]),
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.5)
                    )
                )
                .frame(width: iconSize, height: iconSize)

            // Border overlay
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(lineWidth: 0.5)
                .foregroundColor(
                    colorScheme == .light
                        ? Color.white.opacity(0.2) : Color.white.opacity(0.1)
                )
                .frame(width: iconSize, height: iconSize)

        }
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 2
        )

    }

}


struct SubscriptionIconText: View {

    var subscription: Subscription
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var navManager = NavigationManager.shared

    var body: some View {

        let isSelected =
            navManager.currentEntry?.viewType == .Program
            && navManager.currentEntry?.state.program?.urn == subscription.urn

        Text(subscription.name)
            .tracking(subscription.name.count >= 14 ? -0.4 : 0)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1, reservesSpace: false)
            .foregroundColor(
                (AppConfig.useBrightSubscriptionsBackground && colorScheme == .light)
                    ? .black : .white
            )
            .opacity(isSelected ? 1.0 : 0.5)
//            .animation(.easeInOut(duration: 0.3), value: isSelected)
            .overlay {
                let indicatorSize = 30.0
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white, Color.white.opacity(0.0),
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: indicatorSize / 2
                )
                .frame(width: indicatorSize, height: indicatorSize)
                .clipShape(Circle())
                .opacity(isSelected ? 0.75 : 0)
                .animation(.easeInOut(duration: 0.3), value: isSelected)
                .offset(y: indicatorSize / 2 + 7)
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

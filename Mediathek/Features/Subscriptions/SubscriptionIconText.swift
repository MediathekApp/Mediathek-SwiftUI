//
//  SubscriptionIconText.swift
//  Mediathek
//
//  Created by Jon on 10.06.25.
//

import SwiftUI

struct SubscriptionIconText: View {

    var subscription: Subscription
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var navManager = NavigationManager.shared

    var body: some View {

        let isSelected =
            navManager.currentEntry?.viewType == .Program
            && navManager.currentEntry?.state.program?.urn == subscription.urn

        Text(subscription.name)
//            .tracking(subscription.name.count >= 14 ? -0.4 : 0)
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

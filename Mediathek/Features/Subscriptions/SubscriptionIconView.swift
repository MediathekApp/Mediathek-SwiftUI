//
//  SubscriptionIconView.swift
//  Mediathek
//
//  Created by Jon on 10.06.25.
//

import SwiftUI
import SwiftData
import SDWebImageSwiftUI

struct SubscriptionIconView: View {

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
                    .frame(width: AppConfig.iconSize, height: AppConfig.iconSize)
                    .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: AppConfig.iconSize, height: AppConfig.iconSize)
            }

            if colorScheme == .light {
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
                    .frame(width: AppConfig.iconSize, height: AppConfig.iconSize)
            }

            // Border overlay
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(lineWidth: 0.5)
                .foregroundColor(
                    colorScheme == .light
                        ? Color.white.opacity(0.2) : Color.white.opacity(0.1)
                )
                .frame(width: AppConfig.iconSize, height: AppConfig.iconSize)

        }
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 2
        )

    }

}

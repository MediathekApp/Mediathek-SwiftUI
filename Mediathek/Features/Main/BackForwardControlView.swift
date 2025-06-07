//
//  BackForwardControlView.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

struct BackForwardControlView: View {

    @ObservedObject var navManager = NavigationManager.shared

    var body: some View {

        HStack(spacing: 0) {
            Button(action: { navManager.goBack() }) {
                Image(systemName: "chevron.left")
                    .padding(.horizontal, 6)
            }
            .disabled(!navManager.canGoBack)
            .keyboardShortcut("ö", modifiers: [.command])

            Button(action: { navManager.goForward() }) {
                Image(systemName: "chevron.right")
                    .padding(.horizontal, 6)
            }
            .disabled(!navManager.canGoForward)
            .keyboardShortcut("ä", modifiers: [.command])
        }

    }
}

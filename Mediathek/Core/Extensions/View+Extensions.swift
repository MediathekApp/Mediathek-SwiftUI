//
//  View+Extensions.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import SwiftUICore
#if os(macOS)
import AppKit
#endif

extension View {
    
    func pointingHandCursor(_ active: Bool = true) -> some View {
        self
        #if os(macOS)
            .onHover { inside in
            if inside && active {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
        #endif
    }
    
}

public extension View {
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(FirstAppear(action: action))
    }
}

private struct FirstAppear: ViewModifier {
    let action: () -> ()
    
    // Use this to only fire your block one time
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        // And then, track it here
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

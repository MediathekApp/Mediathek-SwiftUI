//
//  SwipeDetectorView.swift
//  Mediathek
//
//  Created by Jon on 30.05.25.
//

#if os(macOS)
import SwiftUI
import AppKit

enum SwipeDirection {
    case Up
    case Down
    case Left
    case Right
}

struct SwipeDetectorView: NSViewRepresentable {
    
    @State var onSwipe: (SwipeDirection) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: .zero, options: options, owner: context.coordinator, userInfo: nil)
        view.addTrackingArea(trackingArea)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SwipeDetectorView

        init(_ parent: SwipeDetectorView) {
            self.parent = parent
            super.init()
            NSEvent.addLocalMonitorForEvents(matching: .swipe) { [weak self] event in
                
                var direction = SwipeDirection.Down

                if event.deltaX > 0 {
                    direction = .Left
                }
                else if event.deltaX < 0 {
                    direction = .Right
                }
                else if event.deltaY > 0 {
                    direction = .Up
                }
                
                self?.parent.onSwipe(direction)

                return event
            }
        }

    }
}
#endif

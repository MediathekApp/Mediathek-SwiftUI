//
//  PreciseScrollView.swift
//  Mediathek
//
//  Created by Jon on 30.05.25.
//
#if os(macOS)
import SwiftUI
import AppKit

struct ScrollOffsetCoordinator: NSViewRepresentable {

    @StateObject var scrollOffsetStore: ScrollOffsetStore
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            xOffset: $scrollOffsetStore.xOffset,
            yOffset: $scrollOffsetStore.yOffset
        )
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.updateOffsetsIfNeeded(
                scrollOffsetStore.xOffset,
                scrollOffsetStore.yOffset,
                animationDuration: scrollOffsetStore.animationDuration
            )
        }
    }

    class Coordinator: NSObject {
        @Binding var xOffset: CGFloat?
        @Binding var yOffset: CGFloat?
        weak var scrollView: NSScrollView?
        var observer: NSObjectProtocol?
        var isUpdatingFromScroll = false
        var isUpdatingFromState = false
        var initialXOffset: CGFloat?
        var initialYOffset: CGFloat?

        init(
            xOffset: Binding<CGFloat?>,
            yOffset: Binding<CGFloat?>
        ) {
            _xOffset = xOffset
            _yOffset = yOffset
        }

        deinit {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func attach(to view: NSView) {
            DispatchQueue.main.async {
                guard let scrollView = self.findScrollView(from: view),
                      self.scrollView !== scrollView else { return }

                self.scrollView = scrollView
                
                self.initialXOffset = scrollView.contentView.bounds.origin.x
                self.initialYOffset = scrollView.contentView.bounds.origin.y

                scrollView.contentView.postsBoundsChangedNotifications = true
                self.observer = NotificationCenter.default.addObserver(
                    forName: NSView.boundsDidChangeNotification,
                    object: scrollView.contentView,
                    queue: .main
                ) { [weak self] _ in
                    self?.boundsDidChange()
                }

                self.updateOffsetsIfNeeded(self.xOffset, self.yOffset)
            }
        }

        func boundsDidChange() {
            guard let scrollView = scrollView else { return }

            if isUpdatingFromState {
                return // ignore scroll triggered by programmatic update
            }

            DispatchQueue.main.async {
                self.isUpdatingFromScroll = true
                
                let currentOffsetX = scrollView.contentView.bounds.origin.x
                let currentOffsetY = scrollView.contentView.bounds.origin.y

                if self.xOffset == nil || abs(currentOffsetX - self.xOffset!) > 0.5 {
                    self.xOffset = currentOffsetX
                }
                if self.yOffset == nil || abs(currentOffsetY - self.yOffset!) > 0.5 {
                    self.yOffset = currentOffsetY
                }
                
                DispatchQueue.main.async {
                    self.isUpdatingFromScroll = false
                }
            }
        }

        func updateOffsetsIfNeeded(
            _ newOffsetXOrNull: CGFloat?,
            _ newOffsetYOrNull: CGFloat?,
            animationDuration: TimeInterval = 0
        ) {
            
            guard let scrollView = scrollView else { return }

            if isUpdatingFromScroll {
                return // ignore update coming from a user scroll
            }
            
            let newOffsetX: CGFloat = newOffsetXOrNull ?? self.initialXOffset ?? 0
            let newOffsetY: CGFloat = newOffsetYOrNull ?? self.initialYOffset ?? 0

//            print("-- Updating offet: \(newOffset)")

            let currentOffsetX = scrollView.contentView.bounds.origin.x
            let currentOffsetY = scrollView.contentView.bounds.origin.y
            if abs(currentOffsetX - newOffsetX) > 0.5 || abs(currentOffsetY - newOffsetY) > 0.5 {
                isUpdatingFromState = true
                var newBounds = scrollView.contentView.bounds
                newBounds.origin.x = newOffsetX
                newBounds.origin.y = newOffsetY

                if animationDuration > 0 {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = animationDuration // Set your desired animation duration
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        scrollView.contentView.animator().setBoundsOrigin(newBounds.origin)
                    }, completionHandler: {
                        self.isUpdatingFromState = false
                    })
                }
                else {
                    scrollView.contentView.setBoundsOrigin(newBounds.origin)
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                    isUpdatingFromState = false
                }
                
                
            }
        }

        private func findScrollView(from view: NSView) -> NSScrollView? {
            var superview = view.superview
            while let view = superview {
                if let scroll = view as? NSScrollView {
                    return scroll
                }
                superview = view.superview
            }
            return nil
        }
    }
}
#endif

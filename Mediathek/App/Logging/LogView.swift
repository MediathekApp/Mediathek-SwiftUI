//
//  LogView.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

struct LogView: View {
    
    @ObservedObject var logManager: LogManager
    @State private var scrollToBottom: Bool = true

    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0

    private let bottomThreshold: CGFloat = 20
    private let useColors = false

    var body: some View {

        ScrollViewReader { scrollProxy in

            VStack(alignment: .leading) {

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {

                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logManager.messages, id: \.id) { message in
                                Text(message.content)
                                    .font(.system(.body, design: .monospaced))
//                                    .padding(.vertical, 2)
                                    .textSelection(.enabled)
                            }
                        }
                    

                        Color.clear
                            .frame(height: 1)
                            .id("BOTTOM")
                    }
                    .padding()
                    .toolbar {

                        ToolbarItem {
                            Button {
                                self.logText = String()
                                self.logTextColored = AttributedString()
                                self.logManager.messages = []
                            } label: {
                                Label("Clear Log", systemImage: "trash")  // A nice, clear icon
                            }
                            .disabled(self.logManager.messages.isEmpty)
                            .keyboardShortcut("k")
                        }

                        ToolbarItem {
                            Button {
                                scrollProxy.scrollTo("BOTTOM", anchor: .bottom)
                                // Also, explicitly enable auto-scrolling if the user wanted to "catch up"
                                self.scrollToBottom = true
                            } label: {
                                Label(
                                    "Scroll to Bottom",
                                    systemImage: "arrow.down.left"
                                )
                            }
                            .disabled(self.scrollToBottom == true)
                        }

                        #if os(macOS)
                        ToolbarItem {
                            Button {
                                logManager.exportLogsToFile()
                            } label: {
                                Label(
                                    "Share",
                                    systemImage: "square.and.arrow.up"
                                )
                            }
                        }
                        #endif
                    }
                    .background(
                        // This GeometryReader correctly measures the content (VStack) height
                        GeometryReader { contentGeo in
                            Color.clear.onAppear {
                                contentHeight = contentGeo.size.height
                                logLayoutInfo(
                                    "Initial contentHeight: \(contentHeight)"
                                )
                            }
                            .onChange(of: logManager.messages.count) { oldState, newState in
                                contentHeight = contentGeo.size.height
                                logLayoutInfo(
                                    "Content height updated to: \(contentHeight)"
                                )
                            }
                        }
                    )
                    .overlay(
                        // This GeometryReader captures the scroll offset
                        GeometryReader { overlayGeo in
                            Color.clear
                                .preference(
                                    key: LogViewScrollOffsetPreferenceKey.self,
                                    value: overlayGeo.frame(
                                        in: .named("ScrollView")
                                    ).minY
                                )
                        }
                    )
                }
                .background(
                    GeometryReader { scrollGeo in
                        Color.clear.onAppear {
                            scrollViewHeight = scrollGeo.size.height
                            logLayoutInfo(
                                "Initial scrollViewHeight (ScrollView frame): \(scrollViewHeight)"
                            )
                        }
                        .onChange(of: scrollGeo.size) { oldState, newState in
                            scrollViewHeight = newState.height
                            logLayoutInfo(
                                "ScrollView height updated to: \(scrollViewHeight)"
                            )
                        }
                    }
                )
                .coordinateSpace(name: "ScrollView")  // This should be on the ScrollView itself
                .onPreferenceChange(LogViewScrollOffsetPreferenceKey.self) {
                    newOffset in
                    self.scrollOffset = newOffset
                    logLayoutInfo("\n--- ScrollOffset Update ---")
                    logLayoutInfo("newOffset: \(newOffset)")
                    logLayoutInfo("contentHeight: \(contentHeight)")
                    logLayoutInfo("scrollViewHeight: \(scrollViewHeight)")  // Now this should be correct
                    logLayoutInfo("current scrollToBottom: \(scrollToBottom)")

                    let scrollableHeight = contentHeight - scrollViewHeight
                    logLayoutInfo("scrollableHeight: \(scrollableHeight)")

                    // Re-evaluate scrollToBottom
                    if scrollableHeight <= 0 {  // Content fits, always auto-scroll
                        logLayoutInfo(
                            "Content fits, setting scrollToBottom = true"
                        )
                        self.scrollToBottom = true
                    } else {  // Content overflows, check scroll position
                        // We are at the bottom if the absolute scroll offset is close to the scrollable height
                        // Note: newOffset is negative when scrolled down
                        let isAtBottom =
                            abs(newOffset) >= scrollableHeight - bottomThreshold
                        logLayoutInfo(
                            "isAtBottom condition: abs(\(newOffset)) >= \(scrollableHeight) - \(bottomThreshold) -> \(isAtBottom)"
                        )
                        logLayoutInfo("isAtBottom: \(isAtBottom)")

                        if isAtBottom {
                            if !self.scrollToBottom {
                                logLayoutInfo(
                                    "User scrolled back to bottom, setting scrollToBottom = true"
                                )
                            }
                            self.scrollToBottom = true
                        } else {
                            if self.scrollToBottom {
                                logLayoutInfo(
                                    "User scrolled away from bottom, setting scrollToBottom = false"
                                )
                            }
                            self.scrollToBottom = false
                        }
                    }
                    logLayoutInfo("New scrollToBottom state: \(scrollToBottom)")
                    logLayoutInfo("---------------------------\n")
                }
                .onChange(of: logManager.messages.count) { _, _ in
                    logLayoutInfo("\n--- Message Count Change ---")
                    logLayoutInfo("scrollToBottom flag: \(scrollToBottom)")
                    logLayoutInfo("contentHeight: \(contentHeight)")
                    logLayoutInfo("scrollViewHeight: \(scrollViewHeight)")

                    DispatchQueue.main.async {
                        if scrollToBottom && contentHeight > scrollViewHeight {
                            logLayoutInfo(
                                "Scrolling to bottom (content overflowed)."
                            )
                            scrollProxy.scrollTo("BOTTOM", anchor: .bottom)
                        } else if scrollToBottom
                            && contentHeight <= scrollViewHeight
                        {
                            logLayoutInfo("Scrolling to bottom (content fits).")
                            scrollProxy.scrollTo("BOTTOM", anchor: .bottom)
                        } else {
                            logLayoutInfo(
                                "Not scrolling to bottom (scrollToBottom is false)."
                            )
                        }
                    }
                    logLayoutInfo("---------------------------\n")
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            if self.scrollToBottom {
                                logLayoutInfo(
                                    "User initiated scroll, setting scrollToBottom = false"
                                )
                            }
                            self.scrollToBottom = false
                        }
                )
            }

        }
        .onFirstAppear {
            appendNewMessages(from: logManager.messages)
        }

    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    @State private var logText = String()
    @State private var logTextColored = AttributedString()
    @State private var lastMessageID: UUID?

    private func appendNewMessages(from messages: [LogMessage]) {
//
//        var startAppending = lastMessageID == nil
//        for message in messages {
//            if !startAppending && message.id == lastMessageID {
//                startAppending = true
//                continue  // Skip the last seen message
//            }
//            if startAppending {
//                if useColors {
//                    var line = AttributedString(
//                        "[\(formattedDate(message.timestamp))] \(message.content)\n"
//                    )
//                    switch message.level {
//                    case .error: line.foregroundColor = .red
//                    case .warning: line.foregroundColor = .orange
//                    case .debug: line.foregroundColor = .gray
//                    case .info: line.foregroundColor = .primary
//                    }
//                    logTextColored += line
//                }
//                logText += "[\(formattedDate(message.timestamp))] \(message.content)\n"
//
//                lastMessageID = message.id
//            }
//        }

    }

}

struct LogViewScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}


// For debugging:
internal let shouldLogLayoutInfo = false
internal func logLayoutInfo(_ message: String) {
    if !shouldLogLayoutInfo { return }
    print(message)
}

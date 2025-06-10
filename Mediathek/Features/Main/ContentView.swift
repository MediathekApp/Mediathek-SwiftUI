//
//  ContentView.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import SwiftData
import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

struct ContentView: View {

    @Environment(\.colorScheme) var colorScheme

    @State private var searchFieldFrame: CGRect = .zero  // State to store the frame
    @State private var showDownloadsButton = true
    @State private var isTargetByDrop = false
    @State private var scrollOffsetStore = ContentViewScrollOffsetStore()
    @State private var scrollToTopToggle = false
    @StateObject private var store: ContentViewModel = ContentViewModel.shared
    @AppStorage("searchText") private var searchText = ""
    @ObservedObject var navManager = NavigationManager.shared
    #if os(macOS)
        @ObservedObject var dockState = DockState.shared
    #endif

    @Namespace private var topID  // = "top"
    private let provider = SerperDevSearchService()

    var body: some View {

        let subscriptionsViewable =
            navManager.currentEntry?.viewType != .Item
        let subscriptionsVisible =
            (store.showSubscriptions && subscriptionsViewable)

        ZStack {

            VStack(spacing: 0) {

                #if os(macOS)
                    SwipeDetectorView { direction in
                        switch direction {
                        case .Left:
                            navManager.goBack()
                        case .Right:
                            navManager.goForward()
                        default:
                            break
                        }

                    }.frame(height: 0)
                #endif

                if let currentEntry = navManager.currentEntry {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical) {

                            VStack(spacing: 0) {

                                VStack(spacing: 0) {

                                    let visibleHeight: CGFloat =
                                        subscriptionsVisible
                                        ? AppConfig.subscriptionsDockHeight : 0

                                    SubscriptionsView()
                                        .transition(
                                            .move(edge: .top).combined(
                                                with: .opacity
                                            )
                                        )
                                        .id(topID)
                                        .offset(
                                            y:
                                                -(AppConfig
                                                .subscriptionsDockHeight
                                                - visibleHeight) / 2
                                        )
                                        .frame(height: visibleHeight)
                                        .clipped()
                                }

                                view(for: currentEntry)

                            }
                            #if os(macOS)
                                .overlay {
                                    ScrollOffsetCoordinator(
                                        scrollOffsetStore: scrollOffsetStore
                                    ).frame(width: 0, height: 0)
                                }
                            #endif
                            .onChange(of: scrollToTopToggle) {
                                oldState,
                                newState in
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut) {

                                        self.scrollOffsetStore
                                            .animationDuration =
                                            1.0
                                        self.scrollOffsetStore.yOffset = nil  // top

                                        DispatchQueue.main.async {
                                            self.scrollOffsetStore
                                                .animationDuration = 0
                                        }
                                    }
                                }
                            }

                        }
                        .background(
                            backgroundColorForNavigationEntry(
                                navManager.currentEntry
                            )
                        )
                        .onChange(of: navManager.currentEntry) {
                            oldState,
                            newState in

                            self.scrollTo(
                                y: newState?.state.scrollOffset,
                                iterations: 4
                            )

                        }

                    }

                } else {
                    ZStack {

                        #if os(macOS)
                            VisualEffectView(
                                material: .sidebar,
                                blendingMode: .behindWindow,
                                state: .followsWindowActiveState
                            )
                            .edgesIgnoringSafeArea(.all)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #endif

                    }

                }

            }

        }

        .onAppear {
            if navManager.currentEntry == nil {
                goHome()
            }
        }

        #if os(iOS)
            // TODO:
            .searchable(
                text: $searchText,
                placement: .toolbar
            ) /* {

                    ForEach(queryStore.suggestions) { suggestion
                        Text(suggestion.name ?? "?")
                            .searchCompletion(suggestion.name ?? "?")
                    }
                    .searchSuggestions(.hidden, for: .content)

                }*/
            .searchSuggestions {
                HStack {
                    Text("Sendung")
                    Spacer()
                    Text("SENDUNG")
                }.searchCompletion("foo")
            }
            .onSubmit(of: .search) {
                search(searchText)
            }
        #endif

        #if os(macOS)
            .onDrop(
                of: ["public.utf8-plain-text"],
                isTargeted: $isTargetByDrop
            ) { providers -> Bool in

                // provider.loadDataRepresentation API is broken - providers.types is empty when dropping an linked image.
                // We use NSPasteboard here.

                let pasteboard = NSPasteboard(name: .drag)

                if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) {
                    if let firstURL = urls.first as? URL {
                        log("\(firstURL)")
                        search(
                            firstURL.absoluteString,
                        )
                        return true
                    }
                }

                if let strings = pasteboard.readObjects(forClasses: [
                    NSString.self
                ]) {
                    if let firstString = strings.first as? String {
                        log("\(firstString)")
                        search(firstString)
                        return true
                    }
                }

                return false
            }

            .onChange(
                of: dockState.droppedText,
                { oldState, newState in
                    if let newState {
                        log("Got from Dock: \(newState)")
                        search(newState)
                    }
                }
            )
        #endif

        .toolbar {

            // Left Side: Back, Forward, Home
            ToolbarItemGroup(placement: .navigation) {

                BackForwardControlView()

                Button(action: {

                    goHome()

                }) {

                    Label(
                        "Start",  //Entdecken
                        systemImage: "house"  //binoculars
                    )

                    //                    Image(systemName: "binoculars")
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])

            }

            ToolbarItemGroup(placement: .secondaryAction) {

                #if os(macOS)
                    SuggestionSearchField(
                        text: $searchText,
                        onSelectSuggestion: { suggestion in

                            if let programs = suggestion.programs {
                                if !programs.isEmpty {
                                    let urn = programs.first
                                    if let urn {
                                        GoToProgram(
                                            urn,
                                        )
                                        return
                                    }
                                }
                            }

                            search(suggestion.query)

                        },
                        onSearch: { query in
                            search(query)
                        }
                    )
                    .frame(width: AppConfig.searchFieldWidth, alignment: .center)
                    .frame(minWidth: 150, maxWidth: .infinity)
                #endif

            }

            ToolbarItemGroup(placement: .automatic) {

                Button(action: {
                    withAnimation(.easeInOut) {
                        if store.showSubscriptions
                            && (scrollOffsetStore.yOffset == nil
                                || scrollOffsetStore.yOffset! <= 10)
                        {
                            // (a) User is at top and Subscriptions are visible → hide
                            store.showSubscriptions = false
                        } else if !store.showSubscriptions {
                            // (c) Subscriptions are hidden → reveal them
                            store.showSubscriptions = true
                        } else {
                            // (b) Subscriptions visible but scrolled down → scroll up
                            scrollToTop()
                        }
                    }
                }) {
                    //                    Text("S")
                    Label(
                        "Abonnements",
                        systemImage: subscriptionsVisible
                            ? "pin.circle.fill" : "pin.circle"
                    )

                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(!subscriptionsViewable)
                .onChange(of: store.showSubscriptions) { oldState, newState in
                    if /*oldState != newState &&*/
                    newState == true {
                        scrollToTop()
                    }
                }

            }

        }

    }

    internal func scrollToTop() {
        scrollToTopToggle.toggle()
    }

    internal func scrollTo(y: CGFloat?, iterations: Int = 1) {

        // LazyVStack needs multiple iterations to fully layout its views.
        // This recursive calling is a (suboptimal) temporary solution.

        DispatchQueue.main.async {  //After(deadline: DispatchTime.now() + 0.5) {
            scrollOffsetStore.yOffset = y

            if iterations > 1 /*&& y != nil*/ {
                scrollTo(y: y, iterations: iterations - 1)
            }
        }

    }

    internal static func loadProgram(
        _ urn: String,
        maxAge: TimeInterval = 60 * 10,
    ) {

        GoToProgram(urn, maxAge: maxAge)

    }

    internal func loadItem(
        _ urn: String,
        maxAge: TimeInterval = MetadataCacheMaxAge
    ) {

        MetadataStore.shared.requestItem(
            for: urn,
            maxAge: maxAge
        ) { item, source in

            let state = NavigationEntryState()
            state.item = item
            navManager.go(
                to: NavigationEntry(
                    viewType: .Item,
                    state: state
                )
            )

        }

    }

    internal func search(_ query: String) {

        if query.starts(with: "https://") || query.starts(with: "urn:") {
            if query.starts(with: "urn:") && query.contains(":program:") {
                ContentView.loadProgram(
                    query,
                    maxAge: 0,
                )  // maxAge 0 for testing!
            }
            if query.starts(with: "urn:") && query.contains(":item:") {
                loadItem(query, maxAge: 0)
            }
            if query.starts(with: "https://") {
                loadItem(query, maxAge: 0)
            }
        } else {
            performWebSearchWithCache(query)
        }

    }

    internal func goHome() {

        MetadataStore.shared.requestExplorePage(
            for: "urn:mediathek:recommendations:recent",
        ) { contents, source in

            let state = NavigationEntryState()
            let page = ExploreViewModel()
            page.contents = contents
            state.explorePage = page

            navManager.go(
                to: NavigationEntry(
                    viewType: .Explore,
                    state: state
                )
            )

        }

    }

    internal func performWebSearchWithCache(
        _ query: String,
        maxAge: TimeInterval = 60 * 60
    ) {

        RecommendationService.shared.track(urnOrQuery: query)

        func finishWithResponse(
            _ error: Error?,
            _ searchResponse: SerperDevResponse?
        ) {

            if let error {
                log("\(error)", .error)
                return
            }

            if let searchResponse {
                let state = NavigationEntryState()
                let search = Search(query: query, response: searchResponse)
                state.search = search
                navManager.go(
                    to: NavigationEntry(
                        viewType: .Search,
                        state: state
                    )
                )

                let dispatchGroup = DispatchGroup()
                var urns: [String] = []

                // 1. Collect all URNs first
                for searchResult in searchResponse.organic {

                    dispatchGroup.enter()
                    MetadataCollector.shared.getUrnForUrl(
                        url: searchResult.link
                    ) {
                        urn in

                        DispatchQueue.main.async {
                            if let urn = urn {
                                log("- URN: \(urn)")
                                urns.append(urn)

                                var type: SearchResultType = .Item
                                if URNGetValueAtIndex(urn, 3) == "program" {
                                    type = .Program
                                }

                                let store = SearchResultRowModelRepository
                                    .shared.forSearchResult(
                                        searchResult
                                    )
                                store.urn = urn
                                store.type = type

                            } else {
                                log("- No URN for \(searchResult.link)")
                                SearchResultRowModelRepository.shared
                                    .forSearchResult(
                                        searchResult
                                    ).type = .Invalid
                            }
                        }

                        dispatchGroup.leave()

                    }

                }

                // 2. Once all URNs are collected, perform the single request
                dispatchGroup.notify(queue: .main) {
                    log("✅ All URNs collected: \(urns)")

                    // Make a single request with all URNs here
                    MetadataStore.shared.requestMetadataSequentially(
                        urns: urns,
                        maxAge: MetadataCacheMaxAge
                    ) { items in

                        DispatchQueue.main.async {
                            for item in items {
                                if let urn = item.urn {
                                    if let store =
                                        SearchResultRowModelRepository.shared
                                        .forUrn(urn)
                                    {
                                        store.item = item
                                    } else {
                                        log("Issue row not found for \(urn)", .warning)
                                    }
                                }
                            }

                        }

                    }

                }

            }

        }

        let searchUrn =
            "mediathek:search:serper_dev:" + query.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            )!
        MetadataStore.shared.callRemoteCache(
            urn: searchUrn,
        ) { jsonString, lastModified in

            let isExpired =
                lastModified != nil
                && Date.now.timeIntervalSince(lastModified!) > maxAge

            if jsonString != nil && isExpired == false {
                log("Found valid cache entry for search response.")
                do {
                    let decoded = try JSONDecoder().decode(
                        SerperDevResponse.self,
                        from: jsonString!.data(using: .utf8)!
                    )
                    DispatchQueue.main.async {
                        finishWithResponse(nil, decoded)
                    }
                } catch {
                    log("Failed to decode JSON: \(error)", .error)
                }

            } else {
                log(
                    "Did not find search response in remote cache. Calling search provider..."
                )
                provider.search(query: query) { error, searchResponse in
                    finishWithResponse(error, searchResponse)
                    if let searchResponse {

                        do {
                            let encoded = try JSONEncoder().encode(
                                searchResponse
                            )
                            MetadataStore.shared.storeValueInRemoteCache(
                                for: searchUrn,
                                value: String(data: encoded, encoding: .utf8)!
                            )
                        } catch {
                            log("Failed to encode JSON: \(error)", .error)
                        }

                    }
                }

            }
        }

    }

    internal func backgroundColorForNavigationEntry(_ entry: NavigationEntry?)
        -> Color
    {
        if let entry {
            switch entry.viewType {
            case .Item:
                return colorScheme == .light ? Color(white: 0.97) : .clear
            case .Program, .Explore, .Search:
                return colorScheme == .light ? .white : .clear
            }
        }
        return Color.clear
    }

    internal func refreshAllSubscriptions() {
        SubscriptionManager.shared.refreshAllSubscriptions(
        )
    }

}

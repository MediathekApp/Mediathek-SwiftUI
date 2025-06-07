//
//  MediathekApp.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import SwiftData
import SwiftUI

@main
struct MediathekApp: App {

    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
            SubscriptionItemUserState.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var subscriptionManager: SubscriptionManager =
        SubscriptionManager.shared

    @Environment(\.openWindow) private var openWindow

    init() {
        // Disable the URL cache completely:
        URLCache.shared.removeAllCachedResponses()
        URLSession.shared.configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData // don't cache
        URLSession.shared.configuration.urlCache = nil // don't cache
    }
    
    internal func didBecomeActive() {
        
        CloudBundle.shared.download(from: URL(string: AppConfig.cloudBundleURL)!) { result in

            RecommendationService.shared.loadSearchRecommendations()

            subscriptionManager.scheduleAutoRefresh(
                modelContext: sharedModelContainer.mainContext,
                runInitially: true
            )

        }
        

    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {

        Group {
            #if os(macOS)
            // Main app window
            Window("Mediathek", id: "mainWindow") {
                ContentView()
                    #if (os(macOS))
                        .frame(
                            minWidth: 400,
                            idealWidth: 400,
                            minHeight: 200,
                            idealHeight: 580
                        )

                    #endif
            }
            .keyboardShortcut("0")
            .defaultSize(width: 400, height: 580)
            .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
            .modelContainer(sharedModelContainer)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    didBecomeActive()
                }
            }


            // Downloads
            Window("Downloads", id: "downloads") {
                DownloadListView()
            }
            .keyboardShortcut("l", modifiers: [.command, .option])
            .defaultSize(width: 350, height: 320)


            // Log viewer window
            Window("Log", id: "logWindow") {
                LogView(logManager: LogManager.shared)
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .defaultSize(width: 600, height: 400)

            
            #elseif os(iOS)
            WindowGroup {
                NavigationView {
                    
                    ContentView()
                        .onChange(of: scenePhase) { oldPhase, newPhase in
                            if newPhase == .active {
                                didBecomeActive()
                            }
                        }

                }
            }
            #endif
            
        }

    }

}

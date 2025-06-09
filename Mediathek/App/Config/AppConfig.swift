//
//  AppConfig.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUICore

enum AppConfig {

    #if DEBUG
    static let cloudBundleURL = "https://localhost:4443/repo/Mediathek-MetadataCollector/bundle.js"
    #else
    static let cloudBundleURL = "https://mediathek-static.it.wehlte.com/bundle.js"
    #endif
    
    static let ignoreDownloadAllowed = false
    static let subscriptionsDockHeight = 84.0
    static let useBrightSubscriptionsBackground = true
    static let unseenColor = Color(red: 15.0/255.0, green: 126.0/255.0, blue: 255.0/255.0)
    static let maxFeedItems = 15
    static let maxBatchCollectItems = 15
    static let writeOutDayBeforeYesterday = true // "Vorgestern"

    #if os(macOS)
    static let playWithQuickTimePlayer = true
    #endif

}

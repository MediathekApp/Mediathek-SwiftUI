//
//  AppConfig.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation
import SwiftUI

enum AppConfig {

    #if DEBUG
    static let cloudBundleURL = "https://localhost:4443/repo/Mediathek-MetadataCollector/bundle.js"
    #else
    static let cloudBundleURL = "https://mediathek-static.it.wehlte.com/bundle.js"
    #endif
    
    static let ignoreDownloadAllowed = false
    static let useBrightSubscriptionsBackground = true
    static let unseenColor = Color(red: 15.0/255.0, green: 126.0/255.0, blue: 255.0/255.0)
    static let maxFeedItems = 15
    static let maxBatchCollectItems = 15
    static let writeOutDayBeforeYesterday = true // "Vorgestern"
    
    #if os(macOS)
    static let playWithQuickTimePlayer = true
    #endif

    static let iconSize: CGFloat = 48
    static let subscriptionsDockHeight: CGFloat = 36 + iconSize + 28
    static let subscriptionItemWidth: CGFloat = max(iconSize / 0.7, 80)
    static let searchFieldWidth: CGFloat = 240

}

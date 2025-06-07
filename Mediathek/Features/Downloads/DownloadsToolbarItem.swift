//
//  DownloadsToolbarItem.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

struct DownloadsToolbarItem: ToolbarContent {

    @StateObject private var downloadManager = DownloadManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some ToolbarContent {

        let showDownloadsButton = !downloadManager.downloads.isEmpty

        if showDownloadsButton {
            ToolbarItem {

                Button(action: {
                    openWindow(id: "downloads")
                }) {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }

            }
        }

    }

}

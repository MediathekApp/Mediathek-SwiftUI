//
//  DownloadListView.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import SwiftUI

struct DownloadListView: View {
    @StateObject private var downloadManager = DownloadManager.shared

    // State for selection (macOS specific for now with List selection)
    @State private var selectedDownloadID: UUID?

    @FocusState private var focused: Bool

    var body: some View {

        List(selection: $selectedDownloadID) {
            ForEach(downloadManager.downloads) { item in
                DownloadRowView(item: item)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle()) // Make the entire row area tappable
                
                    .simultaneousGesture(TapGesture(count: 2).onEnded {
                        downloadManager.openFile(for: item)
                    })
                    // The touch handler interferes with list selection. We select manually:
                    .simultaneousGesture(TapGesture(count: 1).onEnded {
                        selectedDownloadID = item.id
                    })

            }
            .onDelete { indexSet in  // Keep swipe-to-delete for convenience
                indexSet.forEach { index in
                    let item = downloadManager.downloads[index]
                    if item.status == .downloading || item.status == .paused {
                        downloadManager.cancelDownload(item)
                    }
                    downloadManager.downloads.remove(at: index)
                }
            }

        }
        .listStyle(.plain)
        #if os(macOS)
        .focusable()
        .focused($focused)
        .onKeyPress(action: { keyPress in
            
            // Note: .onKeyPress(.delete) did not fire when tested, also keyPress.key == .delete didn't return true.
            let isDelete = keyPress.key == .delete || keyPress.key == "\u{7F}"
            
            if isDelete {
                if let selectedID = selectedDownloadID,
                   let index = downloadManager.downloads.firstIndex(where: {
                       $0.id == selectedID
                   })
                {
                    let item = downloadManager.downloads[index]
                    if item.status == .completed || item.status == .paused
                        || item.status == .failed || item.status == .canceled
                    {
                        downloadManager.downloads.remove(at: index)
                        selectedDownloadID = nil  // Deselect after removal
                        return .handled
                    } else if item.status == .downloading
                                || item.status == .pending
                    {
                        downloadManager.cancelDownload(item)
                        downloadManager.downloads.remove(at: index)
                        selectedDownloadID = nil
                        return .handled
                    }
                }
            }
            return .ignored

        })
        #endif

    }
}

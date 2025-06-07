//
//  DownloadRowView.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import SDWebImageSwiftUI
import SwiftUI


struct DownloadRowView: View {
    @ObservedObject var item: DownloadItem

    // State to hold the current hint text when hovering over buttons
    @State private var hoveredHint: String? = nil

    let symbolSize = 16.0

    var body: some View {

        HStack(spacing: 12) {
            
            // MARK: Thumbnail
            if let url = item.thumbnailURL {
                WebImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                }
                .frame(width: 160.0/2.3, height: 90.0/2.3)
//                .cornerRadius(8)
                .clipped()
            }

            // MARK: Title and Progress Info
            VStack(alignment: .leading, spacing: 2) {

                Text(item.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                //                    .strikethrough(item.status == .canceled, color: .gray)

                if item.status == .downloading {
                    // Show progress bar only when downloading or paused
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: item.progress
                        )
                        .allowsHitTesting(false) //
                }

                // Unified Progress Info label
                Text(hoveredHint ?? item.statusText)  // Show hint if available, else status text
                    .font(.caption)
                    .opacity(0.8)
                    //.foregroundColor(.secondary)  // Always gray
                    .lineLimit(2)  // Allow error/status message to wrap
            }

            // MARK: Action Buttons
            HStack(spacing: 12) {

                if item.status == .downloading || item.status == .paused {
                    // Pause/Resume button
                    Button(action: {
                        if item.status == .downloading {
                            DownloadManager.shared.pauseDownload(item)
                        } else if item.status == .paused {
                            DownloadManager.shared.resumeDownload(item)
                        }
                    }) {

                        Image(
                            systemName: item.status == .downloading
                                ? "xmark.circle.fill"
                                : "arrow.clockwise.circle.fill"
                        )
                        .resizable()
                        .frame(width: symbolSize, height: symbolSize)

                    }
                    .tint(item.status == .paused ? .orange : nil)
                    .buttonStyle(BorderlessButtonStyle())
                    .onHover { isHovered in  // Mouse over hint
                        hoveredHint =
                            isHovered
                            ? (item.status == .downloading ? "Download stoppen" : "Download fortsetzen")
                            : nil
                    }
                    //                .disabled(item.status == .completed || item.status == .failed || item.status == .canceled)
                }

                /*
                 }
                
                if item.status == .downloading || item.status == .paused {
                    // Pause/Resume button
                    Button(action: {
                        if item.status == .downloading {
                            DownloadManager.shared.pauseDownload(item)
                        } else if item.status == .paused {
                            DownloadManager.shared.resumeDownload(item)
                        }
                    }) {
                        Image(systemName: item.status == .downloading ? "pause.fill" : "play.fill") // Corrected to pause/play
                            .resizable()
                            .frame(width: symbolSize, height: symbolSize)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(item.status == .completed || item.status == .failed || item.status == .canceled)
                    .onHover { isHovered in // Mouse over hint
                        hoveredHint = isHovered ? (item.status == .downloading ? "Pause" : "Resume") : nil
                    }
                }*/

                #if os(macOS)

                    if item.status == .completed {

                        // Reveal file button
                        Button(action: {
                            DownloadManager.shared.revealFile(for: item)
                        }) {

                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: symbolSize, height: symbolSize)

                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .onHover { isHovered in  // Mouse over hint
                            hoveredHint = isHovered ? "Show in Finder" : nil
                        }
                    }

                #endif
                

            }

        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .frame(minWidth: 220)

        // IMPORTANT: Context menu comes after onTapGesture or it might interfere.
        // It's also applied to the row itself, not individual buttons.
        .contextMenu {  // Add context menu
            
            if (item.status == .completed) {
                // Open option
                Button("Öffnen") {
                    DownloadManager.shared.openFile(for: item)
                }
//                .disabled(item.status != .completed)
                
                // Reveal option
                Button("Im Finder zeigen") {
                    DownloadManager.shared.revealFile(for: item)
                }
            }
//            .disabled(item.status != .completed)

//            Divider()  // Separator

            // Copy Address option
            Button("Adresse kopieren") {
                #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        item.url.absoluteString,
                        forType: .string
                    )
                #else  // iOS
                    UIPasteboard.general.string = item.url.absoluteString
                #endif
            }

            // Pause/Resume option
            if item.status == .downloading {
                Button("Stoppen") {
                    DownloadManager.shared.pauseDownload(item)
                }
            } else if item.status == .paused {
                Button("Fortsetzen") {
                    DownloadManager.shared.resumeDownload(item)
                }
            }

            // Remove from List option
            if item.status != .downloading && item.status != .pending { // Don't allow removing active downloads from here
                Button("Von der Liste entfernen") {
                    DownloadManager.shared.downloads.removeAll(where: {
                        $0.id == item.id
                    })
                }
            }
        }

    }
}

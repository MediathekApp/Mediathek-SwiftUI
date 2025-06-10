//
//  ProgramItemView.swift
//  Mediathek
//
//  Created by Jon on 30.05.25.
//

import SDWebImageSwiftUI
import SwiftData
import SwiftUI

struct ItemRow: View {

    @Environment(\.colorScheme) var colorScheme

    var item: Item? = nil
    var subscription: Subscription? = nil
    var searchResult: SerperDevSearchResult?

    var showUnseenIndicator: Bool = false
    var showsSource = true

    let indicatorColor: Color = AppConfig.unseenColor
    let indicatorSize: CGFloat = 8
    let thumbnailSize = CGSizeMake(100, 60)
    let thumbnailCornerRadius = 0.0

    var body: some View {

        HStack(alignment: .top, spacing: 13) {

            VStack(spacing: 0) {

                let imageURL = findBestThumbnailURL()

                // Original thumbnail
                WebImage(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: thumbnailSize.width,
                        height: thumbnailSize.height
                    )
                    .background(Color(white: 0.5, opacity: 0.1))
                    .cornerRadius(thumbnailCornerRadius)
                    .onTapGesture {
                        navigateToItem()
                    }
                    .pointingHandCursor(item != nil)
                    .overlay(
                        Rectangle()
                            .stroke(
                                Color.gray.opacity(0.2),
                                lineWidth: 0.5
                            )
                            .cornerRadius(thumbnailCornerRadius + 1)
                            .frame(width: 100, height: 60)
                    )
                    .overlay {

                        // Reflected thumbnail with gradient mask:
                        WebImage(url: imageURL)
                            .resizable()
                            .frame(width: 100, height: 60)
                            .background(Color(white: 0.5, opacity: 0.1))
                            .cornerRadius(thumbnailCornerRadius)
                            .scaleEffect(x: 1, y: -1)  // Flip vertically
                            .opacity(0.2)  // Slight transparency
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.black, location: 0),
                                        .init(
                                            color: Color.clear,
                                            location: 0.25
                                        ),
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .offset(y: 60 + 1)

                    }

            }

            VStack(alignment: .leading, spacing: 4) {

                VStack(alignment: .leading, spacing: 4) {

                    // Title
                    HStack(alignment: .center, spacing: 6) {
                        if showUnseenIndicator {
                            Circle()
                                .fill(indicatorColor)
                                .frame(
                                    width: indicatorSize,
                                    height: indicatorSize
                                )
                                .offset(y: 1)
                        }

                        Text(renderTitle())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }


                    // Description
                    Text(renderDescription())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                }
                .contentShape(Rectangle())  // Make the whole view area tappable
                .pointingHandCursor(item != nil)
                .onTapGesture {
                    navigateToItem()
                }

                // Source
                if showsSource {
                    HStack(spacing: 4) {
                        let originatorOrPublisher =
                            item?.originator ?? item?.publisher
                        let programName = item?.program?.name
                        let programIdIsValid = item?.program?.id != nil && item?.program?.id.isEmpty == false
                        if let originatorOrPublisher {
                            Text(originatorOrPublisher)
                                .opacity(0.5)
                        }
                        if programName != nil && originatorOrPublisher != nil {
                            Text("›").opacity(0.5)
                        }
                        if let programName {
                            Text(programName)
                                .fontWeight(.medium)
                                .opacity(0.7)
                                .pointingHandCursor(programIdIsValid)
                                .onTapGesture {
                                    if programIdIsValid {
                                        if let urn = item?.urn, let program = item?.program {
                                            let publisherId = URNGetPublisherID(
                                                urn
                                            )
                                            let programUrn =
                                            "urn:mediathek:\(publisherId):program:\(program.id)"
                                            GoToProgram(
                                                programUrn,
                                            )
                                        }
                                    }
                                }
                        }
                    }
                }

                // Buttons and Metadata
                if let item {
                    HStack {

                        let canPlay = ItemCanPlay(item)
                        Button(canPlay ? "Abspielen" : "Nicht verfügbar") {
                            play()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canPlay)

                        if ItemCanBeDownloaded(item) {
                            ItemDownloadButton(item: item)
                        }

                        Spacer()
                            .frame(width: 12)

                        if item.broadcasts != nil {
                            Text(renderDate())
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        if let duration = item.duration {
                            Text("Dauer: \(ItemFormatDuration(duration))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Stretch to full width
                Spacer()
                    .frame(height: 0)
                    .frame(maxWidth: .infinity)

            }
            .frame(minHeight: 70)

        }
        .contextMenu {
            if let webpageURL = item?.webpageURL {
                Button("Web-URL kopieren") {
                    copyToPasteboard(webpageURL)
                }
            }
            if let urn = item?.urn {
                Button("URN kopieren") {
                    copyToPasteboard(urn)
                }
            }
        }
        
    }
    
    internal func findBestThumbnailURL() -> URL {
        if let item {
            return ItemFindBestImageForThumbnail(item)
        }
        return URL(string: "about:blank")!
    }

    internal func markSeen() {
        if let item,
            let subscription = NavigationManager.shared.currentEntry?.state
                .subscription,
            let program = NavigationManager.shared.currentEntry?.state.program
        {
            SubscriptionManager.shared.markSeen(
                item: item,
                subscription: subscription,
                program: program,
            )
        }
    }

    internal func play() {
        markSeen()
        if let item {
            ItemPlay(item)
        }
    }

    internal func navigateToItem() {

        markSeen()

        if let item {

            let navManager = NavigationManager.shared

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

    internal func renderTitle() -> String {

        // We start with the search result title, because swapping it would interrupt a user who is reading it:
        if let title = searchResult?.title {
            if !title.isEmpty { return title }
        }

        if let title = item?.title {
            if !title.isEmpty { return title }
        }
        return ""
    }

    internal func renderDescription() -> String {

        // We start with the search result description, because swapping it would interrupt a user who is reading it:
        if let description = searchResult?.snippet {
            if !description.isEmpty { return description }
        }

        if let description = item?.description {
            if !description.isEmpty {
                // Remove linebreaks:
                return
                    description
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
            }
        }

        return ""

    }

    internal func renderDate() -> String {
        if let broadcasts = item?.broadcasts {
            let date = Date(timeIntervalSince1970: broadcasts)
            return ItemRenderRelativeDate(date)
        }
        return ""
    }

}

#Preview {
    ItemRow(item: ItemDemo())
        .frame(width: 550, alignment: .leading)
}

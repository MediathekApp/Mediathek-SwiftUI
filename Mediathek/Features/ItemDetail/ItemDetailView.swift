//
//  ItemDetailView.swift
//  Mediathek
//
//  Created by Jon on 29.05.25.
//

import SDWebImageSwiftUI
import SwiftUI

struct ItemDetailView: View {

    static let detailsLabelMinWidth = 80.0

    var state: NavigationEntryState

    @State private var isHovering = false

    @Environment(\.colorScheme) var colorScheme

    private func renderDurationAndRelativeDate() -> AttributedString {

        let item = state.item
        
        var relativeDateString = ""
        if let broadcasts = item?.broadcasts {
            let date = Date(timeIntervalSince1970: broadcasts)
            relativeDateString = ItemRenderRelativeDate(date)
        }

        var attributed = AttributedString(
            "\(ItemFormatDuration(item?.duration ?? 0)) | " + relativeDateString
        )

        if let range = attributed.range(of: relativeDateString) {
            attributed[range].font = .body.bold()
        }

        return attributed
        
    }

    @State private var imageLoaded = false

    var body: some View {

        let item = state.item
        let canPlay = ItemCanPlay(item)

        Group {
            VStack(spacing: 16) {

                // MARK: - Preview Image with Overlay
                ZStack {
                    ZStack(alignment: .bottomLeading) {

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.4),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .zIndex(1)
                        .frame(height: 80)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                
                                let program = item?.program
                                let hasProgramLink = item?.program != nil && item?.urn != nil

                                HStack {
                                    Text(
                                        item?.program?.name ?? item?.publisher
                                            ?? ""
                                    )
                                    .font(.system(size: 14))
                                    .bold()
                                    .foregroundColor(
                                        Color(white: 1, opacity: 0.8)
                                    )
                                    .shadow(
                                        color: Color(
                                            .sRGBLinear,
                                            white: 0,
                                            opacity: 0.5
                                        ),
                                        radius: 2.0,
                                        x: 0,
                                        y: 2
                                    )
                                    .pointingHandCursor(hasProgramLink)
                                    .onTapGesture {
                                        if let urn = item?.urn {
                                            if let program {
                                                let publisherId = URNGetPublisherID(urn)
                                                let programUrn = "urn:mediathek:\(publisherId):program:\(program.id)"
                                                GoToProgram(programUrn)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Text(renderDurationAndRelativeDate())
                                        .textSelection(.enabled)
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            Color(white: 1, opacity: 0.8)
                                        )
                                        .shadow(
                                            color: Color(
                                                .sRGBLinear,
                                                white: 0,
                                                opacity: 0.5
                                            ),
                                            radius: 2.0,
                                            x: 0,
                                            y: 2
                                        )

                                }

                                Text(item?.title ?? "")
                                    .lineLimit(2)
                                    .textSelection(.enabled)
                                    .font(.system(size: 24))
                                    .bold()
                                    .foregroundColor(.white)
                                    .shadow(
                                        color: Color(
                                            .sRGBLinear,
                                            white: 0,
                                            opacity: 0.5
                                        ),
                                        radius: 2.0,
                                        x: 0,
                                        y: 2
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )  // 👈 Add this
                            }
                            .padding(),
                            alignment: .bottomLeading
                        )

                        ZStack {
                            Rectangle()
                                .fill(Color.black)

                            if let previewImage = item?.image?.variants.first {

                                WebImage(url: URL(string: previewImage.url)!)
                                    .onSuccess { _, _, _ in
                                        DispatchQueue.main.async {
                                            imageLoaded = true
                                        }
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .opacity(imageLoaded ? 1 : 0)
                                    .animation(
                                        .easeInOut(duration: 0.5),
                                        value: imageLoaded
                                    )

                            }
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .zIndex(0)
                        //                    .background(Color.black)

                    }

                    if canPlay {
                        // Play button
                        Image(systemName: "play.circle")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .opacity(isHovering ? 0.8 : 0.0)
                            .animation(
                                .easeInOut(duration: 0.3),
                                value: isHovering
                            )
                            .onTapGesture {
                                play()
                            }
                            .onHover { hovering in
                                withAnimation {
                                    isHovering = hovering
                                }
                            }

                    }
                }

                // MARK: - Content Area
                HStack(alignment: .top, spacing: 16) {

                    // Left Column: Button
                    VStack(alignment: .trailing, spacing: 8) {

                        Button(canPlay ? "Abspielen" : "Nicht verfügbar") {
                            play()
                        }   
                        .disabled(!canPlay)
                        .padding(.vertical, 4)
                        
                        if let item {
                            if ItemCanBeDownloaded(item) {
                                ItemDownloadButton(item: item)
                            }
                        }

                    }
                    .frame(minWidth: 110, alignment: .trailing)

                    // Vertical Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1)

                    // Right Column: Text Content and Details
                    VStack(alignment: .leading, spacing: 12) {

                        if item?.subtitle?.isEmpty == false {
                            Text(item?.subtitle ?? "")
                                .textSelection(.enabled)
                                .font(.body)
                                .italic()
                        }

                        Text(
                            item?.description ?? """
                                                                """
                        )
                        .textSelection(.enabled)
                        .font(.body)

                        // Details Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Details zum Beitrag:")
                                //                                .font(.headline)
                                .bold()

                            if let duration = item?.duration {
                                DetailRowView(
                                    label: "Dauer:",
                                    value: ItemFormatDuration(duration)
                                )
                            }
                            if let broadcasts = item?.broadcasts {
                                DetailRowView(
                                    label: "Datum:",
                                    value: ItemFormatDate(broadcasts)
                                )
                            }
                            if let programName = item?.program?.name {
                                DetailRowView(label: "Sendung:", value: programName)
                            }

                            if let webpageURL = item?.webpageURL {
                                HStack {
                                    Text("Link:")
                                        .bold()
                                        .frame(
                                            minWidth: ItemDetailView.detailsLabelMinWidth,
                                            alignment: .trailing
                                        )

                                    Link(destination: URL(string: webpageURL)!)
                                    {
                                        Text(
                                            "Beitrag bei \(item?.publisher ?? "") anzeigen"
                                        )
                                        .foregroundColor(
                                            colorScheme == .light
                                                ? Color(white: 0.4)
                                                : Color(white: 0.6)
                                        )
                                        .underline()
                                    }
                                    .pointingHandCursor()

                                }
                            }
                        }
                        .font(.subheadline)

                        // Make the column stretch
                        Spacer().frame(maxWidth: .infinity).frame(height: 0)
                    }
                }
                .padding(.horizontal)

                if let iconName = providerIconImageName(item) {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .opacity(0.6)
                        .frame(width: 40)
                }

                Spacer().frame(minHeight: 2, maxHeight: .infinity)
                
                #if DEBUG
                if let urn = item?.urn {
                    Text(urn)
                        .textSelection(.enabled)
                        .opacity(0.25)
                }
                #endif

            }
        }
        .frame(maxWidth: 800)
//        .onAppear() {
//            markSeen()
//        }
//        .onChange(of: state.item) { oldState, newState in
//            markSeen()
//        }
    }
    
    internal func providerIconImageName(_ item: Item?) -> String? {
        return nil
    }

    internal func play() {

        if let item = state.item {
            ItemPlay(item)
        }

    }

}


//#Preview {
//    ItemDetailView()
//}

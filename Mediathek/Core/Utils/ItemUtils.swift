//
//  ItemUtils.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

func ItemDownloadAllowed(_ item: Item) -> Bool {
    
    if AppConfig.ignoreDownloadAllowed { return true }
    
    if item.downloadAllowed == true { return true }
    
    // The above should be enough, but we double-check:
    if let media = item.media {
        for variant in media {
            if variant.downloadAllowed == true {
                return true
            }
        }
    }
    
    return false
}

func ItemCanBeDownloaded(_ item: Item) -> Bool {
    
    if let media = item.media {
        for variant in media {
            if variant.url.contains(".mp4") && !variant.url.contains(".m3u8") {
                return true
            }
        }
    }
    
    return false
}


func ItemDownload(_ item: Item) {
    
    func findDownloadUrl(_ item: Item) -> String? {
        
        var bestMatch: String? = nil
        
        if let media = item.media {
            for variant in media {
                if variant.url.contains(".mp4") && !variant.url.contains(".m3u8") {
                    // We assume that the quality increases with each entry:
                    bestMatch = variant.url
                }
            }
        }
        
        return bestMatch
        
    }
    
    if let url = findDownloadUrl(item) {
                
        DownloadManager.shared.startDownload(
            from: URL(string: url)!,
            title: item.title ?? "?",
            thumbnailURL: ItemFindBestImageForThumbnail(item)
        )
    }

    
}

func ItemCanPlay(_ item: Item?) -> Bool {
    return item?.media?.isEmpty == false
}



func ItemFindBestImageForThumbnail(_ item: Item) -> URL {
    
    var bestMatch: ImageVariant? = nil
    var bestMatchWidth = 999999;
    
    if let image = item.image {
        for variant in image.variants {
            if bestMatch == nil {
                bestMatch = variant
                bestMatchWidth = variant.width ?? 999999;
            }
            else {
                if let width = variant.width, let _ = variant.height {
                    if width < bestMatchWidth {
                        bestMatch = variant
                        bestMatchWidth = width
                    }
                }
            }
        }
    }
        
    if let bestMatch {
        return URL(string: bestMatch.url)!
    }
 
    return URL(string: "about:blank")!
    
}

func ItemPlay(_ item: Item) {
    
    if let urlString = item.media?.first?.url,
        let url = URL(string: urlString)
    {
        
        if let urn = item.urn {
            RecommendationService.shared.track(urnOrQuery: urn)
        }
        
        #if os(macOS)
        ItemPlayAppKit(item, url)
        #elseif os(iOS)
        ItemPlayUIKit(item, url)
        #endif
        
    } else {
        print("No playable media found.")
    }
    
}


func ItemDemo() -> Item {
    return Item(
        urn: "mediathek:demo:item:0",
        id: "0",
        title: "China: Die Macht der schönen Konkubine",
        subtitle: "",

        program: Program(
            urn: "mediathek:demo:program:0",
            id: "0",
            name: "Terra X",
            items: nil,
            publisher: "ZDF",
            feedCaptured: Date.now.timeIntervalSince1970,
            description: nil,
            homepage: nil,
            image: nil
        ),

        description:
            "In den letzten Jahrzehnten der chinesischen Dynastie (Qing-Dynastie oder Mandschu) dominierte zum ersten Mal eine Frau das Kaiserhaus: Cixi, sie war die Konkubine des Kaisers.",
        media: [],
        image: ItemMetadataImage(variants: [
            ImageVariant(
                url:
                    "about:blank",
                width: 100,
                height: 100
            )
        ]),
        duration: 1000,
        broadcasts: Date.now.timeIntervalSince1970,
        webpageURL: nil,
        publisher: "ZDF",
        originator: nil,
        captured: Date.now.timeIntervalSince1970,
        downloadAllowed: false
    )
}

//
//  MetadataStore.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

class MetadataStore {

    static let shared = MetadataStore()

    func request(
        urn: String,
        maxAge: TimeInterval = MetadataCacheMaxAge,
        strategy: MetadataStoreRequestStrategy = .All,
        callback: @escaping (String?, MetadataStoreSource?, Bool) -> Void,
    ) {

        func getFromLocalCache() -> Bool {
            // First, look for a locally cached version of the program
            let localItem = MetadataCache.shared.get(urn: urn)
            if let localItem, maxAge > 0 {

                // Check if the cached item is still valid
                if Date.now.timeIntervalSince(localItem.date) < Double(maxAge) {
                    // Use the cached item
                    log("Using local cache for \(urn)", .debug)
                    callback(localItem.string, .LocalCache, true)
                    return true
                } else {
                    // Cached item is too old, remove it
                    MetadataCache.shared.data.removeValue(forKey: urn)
                }
            }
            return false
        }

        if strategy != .OnlyCachedElseNilRemoteFirst {
            if getFromLocalCache() { return }
        }

        switch strategy {
        case .OnlyLocallyCachedElseNil:
            callback(nil, nil, false)
            return
        case .OnlyCachedElseNil, .OnlyCachedElseNilRemoteFirst, .All:
            break
        }

        self.callRemoteCache(urn: urn) {
            jsonString,
            lastModified in
            
            if let jsonString, let lastModified {
                
                // Determine if the cached item is expired:
                let isExpired = Date.now.timeIntervalSince(lastModified) > maxAge
                    
                callback(jsonString, .RemoteCache, !isExpired)
                MetadataCache.shared.set(urn: urn, jsonString, lastModified)
                
            } else {
                if strategy == .OnlyCachedElseNil {
                    callback(nil, nil, false)
                } else if strategy == .OnlyCachedElseNilRemoteFirst {
                    if getFromLocalCache() == false {
                        callback(nil, nil, false)
                    }
                } else {
                    callback(nil, nil, false)
                }
            }

        }

    }

    func requestItem(
        for urlOrUrn: String,
        maxAge: TimeInterval = MetadataCacheMaxAge,  // the maximum age in seconds for which the metadata is considered valid
        strategy: MetadataStoreRequestStrategy = .All,
        callback: @escaping (Item?, MetadataStoreSource?) -> Void
    ) {

        // Initially, get the propper URN for the URL.
        MetadataCollector.shared.getUrnForUrl(url: urlOrUrn) { urn in

            guard let urn else {
                log("No valid URN found for \(urlOrUrn)")
                callback(nil, nil)
                return
            }

            self.request(urn: urn, maxAge: maxAge, strategy: strategy) {
                jsonString,
                source,
                notExpired in
                
                if notExpired {
                    callback(
                        jsonString != nil ? decodeJSON(jsonString!, as: Item.self) : nil,
                        source
                    )
                }
                else {
                    self.collectItemMetadata(for: urn, callback: callback)

                }
            }

        }

    }

    func requestProgramWithItems(
        urn: String,
        maxAge: TimeInterval = MetadataCacheMaxAge,
        maxItemAge: TimeInterval = MetadataCacheMaxAge,
        strategy: MetadataStoreRequestStrategy = .All,
        callback: @escaping (Program?, MetadataStoreSource?) -> Void
    ) {

        request(urn: urn, maxAge: maxAge, strategy: strategy) {
            jsonString,
            source, notExpired in
            
            if notExpired || strategy != .All {
                callback(
                    jsonString != nil ? decodeJSON(jsonString!, as: Program.self) : nil,
                    source
                )
            }
            else {
                self.collectProgramWithItems(
                    for: urn,
                    maxItemAge: maxItemAge,
                    callback: callback
                )
            }
        }


    }

    func requestExplorePage(
        for urn: String,
        strategy: MetadataStoreRequestStrategy = .OnlyCachedElseNilRemoteFirst,
        callback: @escaping (ExplorePageContents?, MetadataStoreSource?) -> Void
    ) {

        request(urn: urn, maxAge: MetadataCacheMaxAge, strategy: strategy) {
            jsonString,
            source,
            notExpired in
            callback(
                jsonString != nil ? decodeJSON(jsonString!, as: ExplorePageContents.self) : nil,
                source
            )
        }


    }

    func requestProgramList(
        for publisherId: String,
        maxAge: TimeInterval = MetadataCacheMaxAge,
        strategy: MetadataStoreRequestStrategy = .All,
        callback: @escaping ([Program]?, MetadataStoreSource?) -> Void
    ) {

        let urn = "urn:mediathek:\(publisherId):programs"

        request(urn: urn, maxAge: maxAge, strategy: strategy) {
            jsonString,
            source, notExpired in
            
            if notExpired {
                callback(
                    jsonString != nil ? decodeJSON(jsonString!, as: [Program].self) : nil,
                    source
                )
            }
            else {
                
                log("Collecting program list for \(publisherId)")
                MetadataCollector.shared.collectProgramList(publisherId: publisherId) {
                    jsonString in
                    if let jsonString {

                        let urn = "urn:mediathek:\(publisherId):programs"

                        log("Storing \(urn) in local cache", .debug)
                        MetadataCache.shared.set(urn: urn, jsonString, Date.now)

                        callback(decodeJSON(jsonString, as: [Program].self), .Collect)
                        self.storeValueInRemoteCache(for: urn, value: jsonString)

                    } else {
                        callback(nil, nil)
                    }
                }
                
            }
            
        }
    }

    internal func callRemoteCache(
        urn: String,
        callback: @escaping (String?, Date?) -> Void
    ) {
        
        guard let remoteUrl = MetadataStore.remoteCacheUrl(for: urn) else {
            log("Invalid remoteCacheUrl", .error)
            callback(nil, nil)
            return
        }
        
        log("Checking remote cache for \(urn) at \(remoteUrl)", .debug)

        var request = URLRequest(url: URL(string: remoteUrl)!)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let now = Date.now

        let task = URLSession.shared.dataTask(
            with: request,
        ) { data, response, error in

            // Measure the time taken for the request
            let elapsed = Date.now.timeIntervalSince(now)
            log(
                "⏱️ \(elapsed * 1000) ms for remote cache request for \(urn)",
                .debug
            )

            DispatchQueue.main.async {

                self.handleRemoteCacheResponse(
                    data: data,
                    response: response,
                    error: error,
                    urn: urn,
                    cacheURL: remoteUrl,
                ) { jsonString, lastModified in

                    callback(jsonString, lastModified)

                }
            }
        }
        task.resume()

    }

    internal func handleRemoteCacheResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        urn: String,
        cacheURL: String,
        callback: @escaping (String?, Date?) -> Void
    ) {

//        log("Handle remote cache response", .debug)

        guard let data = data, error == nil,
            let httpResponse = response as? HTTPURLResponse
        else {
            log(
                "Error fetching metadata for \(urn): \(error?.localizedDescription ?? "Unknown error")",
                .error
            )
            callback(nil, nil)
            return
        }

        if httpResponse.statusCode == 404 {
            log("Remote cache has no entry for \(urn)", .debug)
            callback(nil, nil)
            return
        }

        if let decompressedData = decompress(
            data: data,
            algorithm: usingCompressionAlgorithm
        ), let jsonString = String(data: decompressedData, encoding: .utf8) {

            let lastModifiedHeader =
                httpResponse.allHeaderFields["Last-Modified"] as? String
//            log("Last-Modified: \(lastModifiedHeader ?? "N/A")", .debug)

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")  // super important for fixed format parsing
            formatter.timeZone = TimeZone(secondsFromGMT: 0)  // GMT timezone
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"  // matches RFC 1123 format

            if let lastModified = lastModifiedHeader,
                let date = formatter.date(from: lastModified)
            {

                callback(jsonString, date)

                
            } else {
                log(
                    "No valid Last-Modified header found for \(cacheURL), collecting new metadata",
                    .warning
                )
                //                self.collectMetadata(for: urn, callback: callback)
                callback(nil, nil)
                return
            }

        } else {
            log("Failed to decode metadata for \(urn)", .error)
            //            self.collectMetadata(for: urn, callback: callback)
            callback(nil, nil)
        }
    }

    internal static func remoteCacheUrl(
        for urn: String
    ) -> String? {
        
        let hashedUrl = toSha256(urn)
        let suffix =
            switch usingCompressionAlgorithm {
            case .zlib: ".jsondfl"
            case .none: ""
            }
        
        guard let cachingServerHost = CloudBundle.shared.getConfigString("cachingServer") else {
            return nil
        }

        return "https://\(cachingServerHost)/keys/\(hashedUrl)\(suffix)"
    }

    // Third, perform a local metadata collection:
    internal func collectItemMetadata(
        for urn: String,
        callback: @escaping (Item?, MetadataStoreSource?) -> Void
    ) {

        log("Now collecting metadata for \(urn) locally", .debug)

        MetadataCollector.shared.collectMetadataForItem(urn: urn) { jsonString in
            if let jsonString {

                log("Storing \(urn) in local cache", .debug)
                MetadataCache.shared.set(urn: urn, jsonString, Date.now)

                callback(decodeJSON(jsonString, as: Item.self), .Collect)
                self.storeValueInRemoteCache(for: urn, value: jsonString)

            } else {
                callback(nil, nil)
            }
        }

    }

    internal func storeValueInRemoteCache(
        for urn: String,
        value: String
    ) {

        guard let stringData = value.data(using: .utf8),
            let compressedData = compress(
                data: stringData,
                algorithm: usingCompressionAlgorithm
            )
        else {
            log("Failed to compress data for sending to remote cache", .error)
            return
        }

        log("Sending \(urn) to remote cache", .debug)
        
        guard let url = MetadataStore.remoteCacheUrl(for: urn) else {
            log("Invalid caching server URL", .error)
            return
        }
        
        var request = URLRequest(
            url: URL(string: url)!
        )
        request.httpMethod = "PUT"

        switch usingCompressionAlgorithm {
        case .zlib:
            request.setValue(
                "application/octet-stream",
                forHTTPHeaderField: "Content-Type"
            )
            break
        case .none:
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            break
        }

        request.httpBody = compressedData

        // 4. Create a data task and handle the response
        let task = URLSession.shared.dataTask(with: request) {
            data,
            response,
            error in
            if let error = error {
                log(
                    "Error sending request: \(error.localizedDescription)",
                    .error
                )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                log("Invalid response")
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                log("Successfully updated the resource!", .debug)
                if let data = data,
                    let responseString = String(data: data, encoding: .utf8)
                {
                    log("Response data: \(responseString)", .debug)
                }
            } else {
                log(
                    "Server returned status code \(httpResponse.statusCode)",
                    .error
                )
            }
        }

        task.resume()
    }

    // Batch-read items
    internal func requestMetadataSequentially(
        urns urnsIn: [String],
        maxAge: TimeInterval,
        completion: @escaping ([Item]) -> Void
    ) {
        let urns = urnsIn.prefix(AppConfig.maxBatchCollectItems)

        var collectedItems: [Item] = []
        let group = DispatchGroup()

        func processNext(index: Int) {
            guard index < urns.count else {
                // All done, notify
                completion(collectedItems)
                return
            }

            let urn = urns[index]
            group.enter()

            MetadataStore.shared.requestItem(for: urn, maxAge: maxAge) {
                item,
                source in
                if let item {
                    collectedItems.append(item)
                }
                group.leave()

                // Move on to the next item
                processNext(index: index + 1)
            }
        }

        processNext(index: 0)
    }

    internal func collectProgramWithItems(
        for urn: String,
        //maxFeedAge: TimeInterval,
        maxItemAge: TimeInterval = MetadataCacheMaxAge,
        callback: @escaping (Program?, MetadataStoreSource?) -> Void
    ) {

        log("Collecting program with items for \(urn) locally", .debug)

        MetadataCollector.shared.collectProgramFeed(urn: urn) { feedJson in

            guard let feedJson else {
                log("Failed to read program feed", .error)
                callback(nil, nil)
                return
            }

            guard let feed = decodeJSON(feedJson, as: ProgramFeed.self) else {
                log("Failed to parse program feed", .error)
                callback(nil, nil)
                return
            }

            log("Did read feed with \(feed.items.count) items")

            let feedCaptured = Date.now.timeIntervalSince1970

            var newProgramItems: [Item] = []

            // Try to read items from the local or remote cache:
            self.requestProgramWithItems(
                urn: urn,
                maxAge: MetadataCacheMaxAge,
                strategy: .OnlyCachedElseNil
            ) { cachedProgram, source in

                let feedItemsToProcess = Array(feed.items.prefix(AppConfig.maxFeedItems))

                // Items that we have to collect manually:
                var cacheMissItems: [Item] = []

                for feedItem in feedItemsToProcess {
                    if let cachedItems = cachedProgram?.items {
                        var didHitCache = false
                        for cachedItem in cachedItems {
                            if cachedItem.id == feedItem.id {

                                let cachedItemCaptured =
                                    cachedItem.captured
                                    ?? Date.now.timeIntervalSince1970
                                if Date.now.timeIntervalSince1970
                                    - cachedItemCaptured <= maxItemAge
                                {

                                    // We have a cache hit:
                                    newProgramItems.append(cachedItem)
                                    didHitCache = true
                                    break

                                }

                            }
                        }
                        if didHitCache { continue }
                    }
                    log(
                        "Did miss cache for \(feedItem.id) (max item age: \(maxItemAge))",
                        .debug
                    )
                    cacheMissItems.append(feedItem)
                }

                let publisherId = URNGetPublisherID(urn)
                let programId = URNGetID(urn)
                let urnPrefix = "urn:mediathek:\(publisherId):item:"

                let urns = cacheMissItems.map { item in
                    return urnPrefix + item.id
                }

                self.requestMetadataSequentially(urns: urns, maxAge: maxItemAge)
                { items in

                    newProgramItems.append(contentsOf: items)

                    let sortedItems = newProgramItems.sorted { a, b in
                        return (a.broadcasts ?? 0.0) >= (b.broadcasts ?? 0.0)
                    }

                    self.requestProgramMetadata(for: urn, maxAge: MetadataCacheMaxAge)
                    { programInfo, source in

                        let program = Program(
                            urn: urn,
                            id: programId,
                            name: programInfo?.name ?? programId,
                            items: sortedItems,
                            publisher: programInfo?.publisher,
                            feedCaptured: feedCaptured,
                            description: programInfo?.description,
                            homepage: programInfo?.homepage,
                            image: programInfo?.image,
                        )

                        log("Storing result in local cache", .debug)
                        if let json = encodeToJSON(program) {
                            MetadataCache.shared.set(urn: urn, json, Date.now)
                            self.storeValueInRemoteCache(for: urn, value: json)
                        }

                        callback(program, .Collect)

                    }

                }

            }

        }

    }

    internal func requestProgramMetadata(
        for programUrn: String,
        maxAge: TimeInterval,
        callback: @escaping (Program?, MetadataStoreSource?) -> Void
    ) {

        let publisherId = URNGetPublisherID(programUrn)
        let programId = URNGetID(programUrn)

        requestProgramList(for: publisherId) { list, source in

            let match = list?.first { el in
                el.id == programId
            }
            callback(match, source)

        }

    }

}

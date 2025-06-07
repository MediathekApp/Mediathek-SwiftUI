//
//  MetadataModels.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

enum MetadataStoreRequestStrategy {
    case All
    case OnlyCachedElseNil
    case OnlyCachedElseNilRemoteFirst
    case OnlyLocallyCachedElseNil
}

enum MetadataStoreSource {
    case LocalCache
    case RemoteCache
    case Collect
}


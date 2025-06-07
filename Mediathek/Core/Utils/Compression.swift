//
//  Compression.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation
import Compression

internal let usingCompressionAlgorithm = CompressionAlgorithm.zlib

enum CompressionAlgorithm: CaseIterable {
    case zlib, none

    var algorithm: compression_algorithm? {
        switch self {
        case .zlib: return COMPRESSION_ZLIB
        case .none: return nil
        }
    }

    var name: String {
        return String(describing: self)
    }
}

func compress(data: Data, algorithm: CompressionAlgorithm) -> Data? {

    do {
        switch algorithm {
        case .zlib:
            return try (data as NSData).compressed(
                using: NSData.CompressionAlgorithm.zlib
            ) as Data
        case .none: return data
        }
    } catch {
        print(error.localizedDescription)
    }
    return nil

}

func decompress(data: Data, algorithm: CompressionAlgorithm) -> Data? {

    do {
        switch algorithm {
        case .zlib:
            return try (data as NSData).decompressed(
                using: NSData.CompressionAlgorithm.zlib
            ) as Data
        case .none: return data
        }
    } catch {
        print(error.localizedDescription)
    }
    return nil

}

//
//  Hash.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import CryptoKit
import Foundation

func toSha256(_ input: String) -> String {
    // Convert the string into a Data objectb
    let inputData = Data(input.utf8)

    // Generate SHA256 hash
    let hashed = SHA256.hash(data: inputData)

    // Convert the hash to a hex string
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}


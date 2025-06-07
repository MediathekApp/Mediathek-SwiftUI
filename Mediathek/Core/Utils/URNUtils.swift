//
//  URNUtils.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//


func URNGetValueAtIndex(_ urn: String, _ index: Int) -> String {
    let parts = urn.components(separatedBy: ":")
    if parts.count < index+1 {
        print("URNGetValueAtIndex: Invalid URN \(urn)")
        return ""
    }
    return parts[index]
}

func URNGetPublisherID(_ urn: String) -> String {
    return URNGetValueAtIndex(urn, 2)
}

func URNGetID(_ urn: String) -> String {
    return URNGetValueAtIndex(urn, 4)
}

//
//  Pasteboard.swift
//  Mediathek
//
//  Created by Jon on 09.06.25.
//
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

func copyToPasteboard(_ string: String) {
#if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
#elseif os(iOS)
    UIPasteboard.shared.string = string
#endif
}

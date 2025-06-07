//
//  DockState.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

#if os(macOS)
import AppKit

class DockState: ObservableObject {
    @Published var droppedText: String? = nil
    static let shared = DockState()
}
#endif

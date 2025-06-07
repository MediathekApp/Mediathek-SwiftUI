//
//  ContentViewModel.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

class ContentViewModel: ObservableObject {
    static var shared = ContentViewModel()
    @AppStorage("showSubscriptions") var showSubscriptions = false
}

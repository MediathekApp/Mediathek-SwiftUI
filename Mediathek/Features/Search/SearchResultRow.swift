//
//  SearchResultsView.swift
//  Mediathek
//
//  Created by Jon on 31.05.25.
//

import SwiftUI

struct SearchResultRow: View {
    
    @StateObject var store: SearchResultRowModel
    
    var body: some View {
        
        // For debugging: Show URL
//        if let searchResult = store.searchResult {
//            Text(searchResult.link).textSelection(.enabled).opacity(0.25).italic()
//        }
        
        switch store.type {
        case .Item:
            ItemRow(
                item: store.item,
                searchResult: store.searchResult,
                showsSource: true
            )
        case .Program:
            if let urn = store.urn, let searchResult = store.searchResult, let title = searchResult.title {
                Text("➡️ Sendung: \(title)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .pointingHandCursor()
                    .onTapGesture {
                        GoToProgram(urn, modelContext: modelContext)
                    }
            }
            
        case .Invalid:
            EmptyView()
        }
        //
        
    }
    
    @Environment(\.modelContext) private var modelContext
}


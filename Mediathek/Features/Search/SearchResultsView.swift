//
//  SearchResultsView.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

struct SearchResultsView: View {
    
    var state: NavigationEntryState
    
    var body: some View {
        if let search = state.search {
            
            LazyVStack(alignment: .leading, spacing: 8) {
                
                if let response = search.response {
                    Section {
                        
                        ForEach(response.organic, id: \.link) { searchResult in
                            
                            let store = SearchResultRowModelRepository.shared.forSearchResult(searchResult)
                            if store.urn != nil {
                                
                                SearchResultRow(store: store)
                                    .padding(.vertical, 4)
                                
                            }
                            
                        }
                    } header: {
                        
                        Text("Suchergebnisse für „\(search.query)”")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .padding(.bottom, 4)
                        
                    }
                }
                
            }
            .padding(.horizontal, 16 + 8)
            .padding(.vertical, 16)
            .frame(maxWidth: 800, alignment: .leading)

            
        }
    }
    
}

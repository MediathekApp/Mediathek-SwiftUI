//
//  ExploreView.swift
//  Mediathek
//
//  Created by Jon on 31.05.25.
//

import SwiftUI

struct ExplorePageView: View {

    var state: NavigationEntryState
    @State private var currentCategory: String? = nil
    
    var body: some View {

        VStack(alignment: .leading) {

            if state.explorePage != nil {

                if let contents = state.explorePage?.contents {

                    LazyVStack(alignment: .leading, spacing: 8) {

                        Section {

                            ForEach(contents.items, id: \.id) { item in
                                ItemRow(
                                    item: item,
                                    showsSource: true
                                )
                                .padding(.vertical, 4)
                            }

                        } header: {

                            VStack(alignment: .leading, spacing: 8) {

                                Text("Entdecken")
                                    .font(.system(size: 23, weight: .medium))
                                    .opacity(0.8)

                                if let categories = state.explorePage?.contents?
                                    .categories
                                {
                                    VStack(alignment: .center, spacing: 0) {
                                        Spacer().frame(height: 6)
                                        
                                        CategoryMenuView(
                                            categories: categories,
                                            currentCategory: $currentCategory
                                        ) { selectedCategory in
                                            
                                            changeCategory(selectedCategory)
                                            
                                        }
                                        .frame(
                                            maxWidth: 600,
                                            alignment: .center
                                        )

                                        Spacer()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 8)
                                    }
                                } else {
                                    Spacer().frame(height: 0)
                                }
                            }

                        }

                    }
                    .padding(.horizontal, 16 + 8)
                    .padding(.vertical, 16)
                    .frame(maxWidth: 800, alignment: .leading)

                }
            }

        }
        .onAppear {
            if currentCategory == nil {
                currentCategory = state.explorePage?.contents?.currentCategory
            }
        }
        .onChange(of: state.explorePage?.contents?.currentCategory) { oldValue, newValue in
            currentCategory = newValue
        }

    }
    
    internal func changeCategory(_ category: String) {
        
        if state.explorePage?.contents?.currentCategory == category {
            return
        }
        
        let categories = state.explorePage?.contents?.categories
        
        MetadataStore.shared.requestExplorePage(
            for: "urn:mediathek:recommendations:"+category,
        ) { contents, source in

            if let contents {
                let state = NavigationEntryState()
                let page = ExploreViewModel()
                page.contents = ExplorePageContents(
                    title: contents.title,
                    items: contents.items,
                    categories: categories,
                    currentCategory: category
                )
                state.explorePage = page
                
                NavigationManager.shared.go(
                    to: NavigationEntry(
                        viewType: .Explore,
                        state: state
                    )
                )
            }

        }

        
    }

}

//
//  SuggestionsView.swift
//  Mediathek
//
//  Created by Jon on 01.06.25.
//

//import SwiftUI
//
//struct SuggestionMenuItem: View {
//    
//    @State var suggestion: SearchRecommendation
//    @State private var highlighted: Bool = false
//    
//    var body: some View {
//        HStack {
//            Text("\(suggestion.query)")
//                .lineLimit(1)
//                .padding(.vertical, 3)
//            Spacer()
//        }
//        .padding(.horizontal, 8)
//        .background(highlighted ? Color.blue : Color.clear)
//        .foregroundColor(highlighted ? Color.white : Color.primary)
//        .cornerRadius(3)
//        .onHover { inside in
//            highlighted = inside
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .onTapGesture {
//            if let programUrn = suggestion.programs.first {
//                GoToProgram(programUrn, modelContext: modelContext)
//            }
//        }
//    }
//    
//    @Environment(\.modelContext) private var modelContext
//
//}
//
//struct SuggestionsView: View {
//
//    @StateObject var queryStore: SearchQueryStore
//
//    var body: some View {
//        
//        LazyVStack(alignment: .leading, spacing: 0) {
//            ForEach(queryStore.suggestions, id: \.query) { suggestion in
//                SuggestionMenuItem(suggestion: suggestion)
//            }
//        }
//        .padding(.vertical, 4)
//        .padding(.horizontal, 4)
//        .background(colorScheme == .light ? Color(white: 0.97) : Color(white: 0.1))
//        .cornerRadius(5)
//        .shadow(
//            color: Color.black.opacity(0.2),
//            radius: 10,
//            x: 0,
//            y: 5
//        )
////        .frame(maxWidth: 300)
//        
//    }
//    
//    @Environment(\.colorScheme) var colorScheme
//
//}

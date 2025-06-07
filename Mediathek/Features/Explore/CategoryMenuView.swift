//
//  CategoryMenuView.swift
//  Mediathek
//
//  Created by Jon on 02.06.25.
//
import SwiftUI


struct CategoryMenuView: View {

    var categories: [String]
    @Binding var currentCategory: String?
    
    var onSelectCategory: (String) -> Void
    
    @State private var selectedCategory: String = ""
    
    private let recentsCategory = "recent"
    private let divider = "-"
    private let preferedFeaturedCategories = ["recent"]//,"documentary","magazine","series","talkshow","knowledge"]
    private let maxFeaturedCategories = 5

    var body: some View {
        
        HStack {
            
            Menu {
                ForEach(getAllCategories(), id: \.self) { cat in
                    
                    if cat == "-" {
                        Divider()
                    }
                    else {
                        Button(action: {
                            onSelectCategory(cat)
                        }) {
                            Text(nameForCategory(cat, short: false))
                        }
                    }

                }

            } label: {
//                Label("Themen", systemImage: "chevron.down")
                
                HStack {
                    Text("Themen")
//                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.gray.opacity(0.2)))

            }
            .menuStyle(.borderlessButton)
//            .menuIndicator(.hidden)
            .fixedSize()
            
//            let cats = ["Aktuell","Dokumentation","Magazin","Serie","Talkshow","Wissen"]
//            ForEach(cats, id: \.self) { cat in
//                Button { } label: { Text(cat).lineLimit(1) }.buttonStyle(PlainButtonStyle()).padding(.horizontal, 3)
//            }

            
            Picker("", selection: $selectedCategory) {
                let cats = getFeaturedCategories()
                ForEach(cats, id: \.self) { cat in
                    Text(nameForCategory(cat, short: true))
                    //.font(.system(size: 12, weight: .medium))
                        .tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            if let currentCategory {
                isUpdatingStateInternally = true
                selectedCategory = currentCategory
                DispatchQueue.main.async {
                    isUpdatingStateInternally = false
                }
            }
        }
        .onChange(of: currentCategory ?? "") { oldValue, newValue in
            if oldValue.isEmpty { return }
            isUpdatingStateInternally = true
            selectedCategory = newValue
            DispatchQueue.main.async {
                isUpdatingStateInternally = false
            }
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            if isUpdatingStateInternally == false {
                onSelectCategory(newValue)
            }
        }

    }
    
    @State private var isUpdatingStateInternally: Bool = false

    internal func getFeaturedCategories() -> [String] {

        var cats: [String] = []

        // Get availableCategories without dividers
        let availableCategories = categories.filter { $0 != divider }

        // Go through preferedFeaturedCategories, see if they are in availableCategories
        for cat in preferedFeaturedCategories {
            if availableCategories.contains(cat) {
                cats.append(cat)
            }
        }
        // If we have less than maxFeaturedCategories, fill up with availableCategories
        while cats.count < maxFeaturedCategories {
            if let nextCat = availableCategories.first(where: { !cats.contains($0) }) {
                cats.append(nextCat)
            } else {
                break // No more categories to add
            }
        }

        return cats
    }

    internal func getAllCategories(alphabetically: Bool = true) -> [String] {
        if alphabetically {
            return categories
                .filter { $0 != divider }
                .map { ($0, nameForCategory($0)) }
                .sorted { $0.1 < $1.1 }
                .map { $0.0 }
        }
        return categories
    }
    
    internal func nameForCategory(_ id: String, short: Bool = false) -> String {

        let map: [String:String] = [
            "comedy": short ? "Comedy" : "Comedy & Kabarett",
            "crime": "Krimi",
            "culture": "Kultur",
            "documentary": "Dokumentation",
            "film": "Film",
            "food_cooking": short ? "Kochen" : "Essen & Kochen",
            "kids": "Kinder",
            "knowledge": "Wissen",
            "lifestyle": short ? "Ratgeber" : "Verbraucher & Ratgeber",
            "magazine": "Magazin",
            "music": "Musik",
            "news": "Nachrichten",
            "recent": "Aktuell",
            "reportage": "Reportage",
            "series": "Serie",
            "show": "Shows",
            "society": "Gesellschaft",
            "sports": "Sport",
            "talkshow": "Talkshow",
            "travel_nature": short ? "Reise" : "Reise & Natur",
        ]
        if let value = map[id] {
            return value
        }
        return id
    }

}

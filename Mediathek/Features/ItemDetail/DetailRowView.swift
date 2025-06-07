//
//  DetailRowView.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUICore

struct DetailRowView: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .bold()
                .frame(minWidth: ItemDetailView.detailsLabelMinWidth, alignment: .trailing)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

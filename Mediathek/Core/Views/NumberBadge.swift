//
//  NumberBadge.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import SwiftUI

struct NumberBadge: View {
    let value: Int
    var fontSize: CGFloat = 11
    var backgroundColor: Color = Color(
        hue: 7 / 360,
        saturation: 0.77,
        brightness: 0.86
    )
    var contentColor: Color = .white
    var minSize: CGFloat = 20
    var horizontalPadding: CGFloat = 6

    var body: some View {
        let text = "\(value)"

        Text(text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundColor(contentColor)
            .padding(.horizontal, horizontalPadding)
            .frame(minWidth: minSize, minHeight: minSize)
            .background(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: geometry.size.height / 2)
                        .fill(backgroundColor)
                }
            )
            .fixedSize()
    }
}

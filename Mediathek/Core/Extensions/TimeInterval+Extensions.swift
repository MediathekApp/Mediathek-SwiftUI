//
//  TimeInterval+Extensions.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import Foundation

extension TimeInterval {
    func formattedTime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        formatter.maximumUnitCount = 2 // Show up to two units (e.g., 5m 30s)

        if self.isNaN || self.isInfinite || self < 0 {
            return "N/A"
        } else if self < 60 {
            return String(format: "%.0f Sekunden", self)
        } else {
            return formatter.string(from: self) ?? "N/A"
        }
    }
}

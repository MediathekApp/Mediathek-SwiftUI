//
//  Formatters.swift
//  Mediathek
//
//  Created by Jon on 07.06.25.
//

import Foundation

internal let currentYear4Digits = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).suffix(4)
internal let currentYear2Digits = String(currentYear4Digits.suffix(2))

func ItemFormatDate(_ timestamp: TimeInterval, _ dateStyle: DateFormatter.Style = .medium) -> String {
    let date = Date(timeIntervalSince1970: timestamp)
    return ItemFormatDate(date, dateStyle)
}

func ItemFormatDate(_ date: Date, _ dateStyle: DateFormatter.Style = .medium) -> String {
    
    let languageCode = Locale.current.language.languageCode?.identifier
    let customShortDateFormat: String? = languageCode == "de" ? "d.M." : nil // Custom format for German without leading zeros
    
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.timeZone = TimeZone.current

    if customShortDateFormat != nil && dateStyle == .short {
        formatter.dateFormat = customShortDateFormat!
    } else {
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
    }
    
    var rendered = formatter.string(from: date)
    
    if (dateStyle == .short && !formatter.dateFormat.isEmpty) {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentYear2Digits = String(currentYear % 100)

        if rendered.hasSuffix("." + currentYear2Digits) {
            let index = rendered.index(rendered.endIndex, offsetBy: -2)
            rendered = String(rendered[..<index])
        }
    }

    return rendered
}


func ItemFormatDuration(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return "\(minutes):" + String(format: "%02d", remainingSeconds)
}


func ItemRenderRelativeDate(_ date: Date) -> String {
    
    // Today?
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return "heute"
    }

    // Yesterday?
    if calendar.isDateInYesterday(date) {
        return "gestern"
    }

    // Day before yesterday?
    if AppConfig.writeOutDayBeforeYesterday
        && calendar.isDate(
            date,
            inSameDayAs: calendar.date(
                byAdding: .day,
                value: -2,
                to: Date()
            )!
        )
    {
        return "vorgestern"
    }

    // Any other date
    return "vom \(ItemFormatDate(date, .short))"
    
}

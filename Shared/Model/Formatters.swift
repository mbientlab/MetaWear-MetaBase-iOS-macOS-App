// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

let shortDateTimeFormatter: DateFormatter = {
    let date = DateFormatter()
    date.dateStyle = .short
    date.timeStyle = .short
    return date
}()

let mediumDateFormatter: DateFormatter = {
    let date = DateFormatter()
    date.dateStyle = idiom == .iPhone ? .short : .medium
    date.doesRelativeDateFormatting = true
    date.timeStyle = .none
    return date
}()

let shortTimeFormatter: DateFormatter = {
    let date = DateFormatter()
    date.dateStyle = .none
    date.timeStyle = .short
    return date
}()

extension DateComponentsFormatter {

    static func dayHourMinute() -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }
}

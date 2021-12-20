// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

extension DateComponentsFormatter {

    static func dayHourMinute() -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }
}

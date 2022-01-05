// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum CloudSaveState: Equatable {
    case notStarted
    case saving
    case saved
    case error(Error)

    public static func == (lhs: CloudSaveState, rhs: CloudSaveState) -> Bool {
        switch (lhs, rhs) {
            case (.error, .error), (.saving, .saving), (.saved, .saved), (.notStarted, .notStarted): return true
            default: return false
        }
    }
}

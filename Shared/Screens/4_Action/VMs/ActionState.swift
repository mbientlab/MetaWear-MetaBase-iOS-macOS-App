// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum ActionState: Int, Hashable, Equatable {
    case notStarted
    case working
    case completed
    case timeout
    case error

    var hasOutcome: Bool { self != .notStarted && self != .working }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum ActionState: Hashable, Equatable {
    case notStarted
    /// Percent complete
    case working(Int)
    case completed
    case timeout
    case error(String)

    public var hasOutcome: Bool {
        switch self {
            case .completed: fallthrough
            case .timeout: fallthrough
            case .error: return true
            default: return false
        }
    }

    public var hasError: Bool {
        switch self {
        case .error: return true
        default: return false
        }
    }

    public var info: String {
        switch self {
            case .working(let int): return String(int)
            case .error(let string): return string
            default: return ""
        }
    }
}

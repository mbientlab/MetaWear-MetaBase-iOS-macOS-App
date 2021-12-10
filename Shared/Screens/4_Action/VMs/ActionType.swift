// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum ActionType {
    case stream
    case log
    case downloadLogs

    var title: String {
        switch self {
            case .stream: return "Stream"
            case .log: return "Log"
            case .downloadLogs: return "Download Logs"
        }
    }

    var completedLabel: String {
        switch self {
            case .stream: return "Streaming"
            case .log: return "Logging"
            case .downloadLogs: return "Downloaded"
        }
    }


}

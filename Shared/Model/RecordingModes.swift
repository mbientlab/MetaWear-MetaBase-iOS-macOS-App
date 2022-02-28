// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

public enum RecordingModes: String, Selectable {
    case stream, log, remote

    public var displayName: String { rawValue.capitalized }
    public var id: RawValue { rawValue }
    public var sfSymbol: SFSymbol {
        switch self {
        case .stream: return .stream
        case .log: return .log
        case .remote: return .mechanicalSwitch
        }
    }

    func helpView() -> AnyView? {
        switch self {
        case .stream, .log: return nil
        case .remote: return AnyView(RemoteHelpView(showNewToMetaBase: false))
        }
    }
}

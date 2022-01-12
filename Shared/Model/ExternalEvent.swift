// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

enum ExternalEvent: String, ExternalEvents {
    case onboarding
    case migrate
    case launch

    var url: URL { URL(string: Self.urlPrefix + tag)! }
    var tag: String { rawValue }
    static let urlPrefix = "metabase://"
}

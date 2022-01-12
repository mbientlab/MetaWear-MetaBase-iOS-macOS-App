// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

enum ExternalEvent: String, ExternalEvents {
    case onboarding = "onboarding"
    case migrate = "migrate"

    var url: URL { URL(string: Self.urlPrefix + tag)! }
    var tag: String { rawValue }
    static let urlPrefix = "metabase://"
}

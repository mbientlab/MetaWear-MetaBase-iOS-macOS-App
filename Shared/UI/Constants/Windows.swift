// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

enum Windows: String, CaseIterable {
    case metabaseMain
    case onboarding
    case migration

    var tag: String { rawValue }
    var externalEventURL: URL { URL(string: Self.urlPrefix + tag)! }
    static let urlPrefix = "metabase://"
}

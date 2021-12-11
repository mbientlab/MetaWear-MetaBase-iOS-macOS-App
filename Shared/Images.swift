// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import MetaWear

public enum Images: String {
    case metawearSide = "metawearSide"
    case metawearTop = "metawearTop"

    public var bundleName: String { rawValue }

    public func image() -> Image {
        Image(bundleName)
    }
}

public extension MetaWear.Model {

//    var bundleName: String? {
//        switch self {
//            case .rl: fallthrough
//            case .s: return "metamotionS"
//            case .c: return "metamotionC"
//            case .notFound: return nil
//        }
//    }

    var image: Images { .metawearTop }
}


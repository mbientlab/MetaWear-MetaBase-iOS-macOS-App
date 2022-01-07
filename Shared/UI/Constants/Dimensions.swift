// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI

public extension CGFloat {

#if os(macOS)
    static let screenInset = CGFloat(55)
#elseif os(iOS)
    static let screenInset = idiom == .iPad ? CGFloat(65) : CGFloat(20)
#endif
    static let deviceCellWidth = CGFloat(120)
    static let verticalHoverDelta = CGFloat(12)
    static let headerMinHeight = CGFloat(110)
    static let headerTopPadding = idiom.is_iOS ? CGFloat(40) : 0
}

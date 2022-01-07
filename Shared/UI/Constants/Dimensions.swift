// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI

public extension CGFloat {

    static let screenInset = idiom == .iPad ? CGFloat(65) : CGFloat(55)
    static let deviceCellWidth = CGFloat(120)
    static let verticalHoverDelta = CGFloat(12)
    static let headerMinHeight = CGFloat(110)
    static let headerTopPadding = idiom == .iPad ? CGFloat(40) : 0
}

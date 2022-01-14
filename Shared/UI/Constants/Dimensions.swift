// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public extension CGFloat {

    static let screenInset          = CGFloat(macOS: 55 , iPad: 65 , iOS: 20)
    static let deviceCellWidth      = CGFloat(130)
    static let deviceCellHeight     = CGFloat(320)
    static let verticalHoverDelta   = CGFloat(12)
    static let headerMinHeight      = CGFloat(macOS: 110, iPad: 110, iOS: 70)
    static let headerTopPadding     = CGFloat(macOS: 0  , iPad: 40 , iOS: 20)

    #if os(macOS)
    static let mainWindowMinWidth = MainScene.minWidth
    #elseif os(iOS)
    static let mainWindowMinWidth = UIScreen.main.bounds.shortestSide
    #endif

}

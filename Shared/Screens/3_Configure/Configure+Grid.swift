// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear


extension ConfigureScreen {

    struct Grid: View {

        @EnvironmentObject private var vm: ConfigureVM

        #if os(macOS)
        static let tileWidth = CGFloat(180)
        static let tileHeight = CGFloat(170)
        static private let gridSpacing = CGFloat(12)
        #else
        static let tileWidth = CGFloat(220)
        static let tileHeight = CGFloat(210)
        static private let gridSpacing = CGFloat(25)
        #endif

        static private let gridItemSize = Self.tileWidth
        private let item = GridItem(.adaptive(minimum: gridItemSize, maximum: gridItemSize),
                                    spacing: Self.gridSpacing,
                                    alignment: .leading)

        var body: some View {
            LazyVGrid(columns: [item], alignment: .leading, spacing: Self.gridSpacing) {
                SensorIterator()
            }
            .animation(.interactiveSpring())
            #if os(iOS)
            .padding(.trailing, .screenInset)
            #endif
        }
    }
}


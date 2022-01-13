// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear


extension ConfigureScreen {

    struct Grid: View {

        @EnvironmentObject private var vm: ConfigureVM

        #if os(macOS)
        static let tileWidth = CGFloat(180)
        #else
        static let tileWidth = CGFloat(iPad: 220, max(165, (UIScreen.main.bounds.width - gridSpacing - 16) / 2))
        #endif
        static let tileHeight          = CGFloat(macOS: 170, iPad: 210, iOS: 150)
        static private let gridSpacing = CGFloat(macOS: 12 , iPad: 25 , iOS: 5)

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
            .padding(.trailing, idiom == .iPhone ? 0 : .screenInset)
            .padding(.horizontal, idiom == .iPhone ? 8 : 0)
            #endif
        }
    }
}


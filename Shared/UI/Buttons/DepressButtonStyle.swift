// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct DepressButtonStyle: ButtonStyle {

    var anchor: UnitPoint = .center

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        #if os(iOS)
            .scaleEffect(configuration.isPressed ? 0.94 : 1, anchor: anchor)
        #elseif os(macOS)
            .scaleEffect(configuration.isPressed ? 0.96 : 1, anchor: anchor)
        #endif
            .animation(.spring(), value: configuration.isPressed)
    }
}

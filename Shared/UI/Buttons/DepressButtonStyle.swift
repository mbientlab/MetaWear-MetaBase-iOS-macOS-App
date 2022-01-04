// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct DepressButtonStyle: ButtonStyle {

    var anchor: UnitPoint = .center

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1, anchor: anchor)
            .animation(.spring(), value: configuration.isPressed)
    }
}

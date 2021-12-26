// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct HoverButtonStyle: ButtonStyle {

    var anchor: UnitPoint = .center

    func makeBody(configuration: Configuration) -> some View {
        Style(config: configuration, anchor: anchor)
    }

    struct Style: View {
        var config: Configuration
        var anchor: UnitPoint
        @State private var isHovered = false

        var body: some View {
            config.label
                .scaleEffect(config.isPressed ? 0.96 : 1, anchor: anchor)
                .foregroundColor(isHovered ? .myHighlight : nil)
                .whenHovered { isHovered = $0 }
                .animation(.spring(), value: config.isPressed)
                .animation(.easeOut.speed(3), value: isHovered)
        }
    }
}

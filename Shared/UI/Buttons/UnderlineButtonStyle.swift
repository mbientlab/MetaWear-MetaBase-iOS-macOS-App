// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct UnderlinedButtonStyle: ButtonStyle {

    var color: Color = .myHighlight
    var isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(Style(color: color, isHovered: isHovered))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }

    private struct Style: View {

        var color: Color = .myHighlight
        var isHovered: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            UnderlineRect(cornerRadius: 5, percent: isHovered ? 1 : 0)
                .strokeBorder(lineWidth: 3, antialiased: true)
                .foregroundColor(isEnabled ? color : .myTertiary)
                .animation(.easeOut, value: isEnabled)
        }
    }
}

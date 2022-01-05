// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct UnderlinedButtonStyle: ButtonStyle {

    var color: Color = .myHighlight
    var isHovered: Bool
    var incognitoUnderline: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(Style(config: self))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }

    private struct Style: View {

        var config: UnderlinedButtonStyle
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            UnderlineRect(cornerRadius: 5, percent: config.isHovered ? 1 : 0)
                .strokeBorder(lineWidth: 3, antialiased: true)
                .foregroundColor(isEnabled ? config.color : .myTertiary)
                .opacity(config.isHovered || !config.incognitoUnderline ? 1 : 0)
                .animation(.easeOut, value: isEnabled)
        }
    }
}

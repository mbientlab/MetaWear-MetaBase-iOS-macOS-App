// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct UnderlinedButtonStyle: ButtonStyle {

    var color: Color = .myHighlight
    var isHovered: Bool
    var incognitoUnderline: Bool = false
#if os(iOS)
            let animation = Animation.spring().speed(3)
#else
            let animation = Animation.spring()
#endif

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
#if os(iOS)
            .background(Style(config: self, isPressed: configuration.isPressed))
#else
            .background(Style(config: self, isPressed: false))
#endif
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(animation, value: configuration.isPressed)
    }

    private struct Style: View {

        var config: UnderlinedButtonStyle
        var isPressed: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            UnderlineRect(cornerRadius: 5, percent: config.isHovered || isPressed ? 1 : 0)
                .strokeBorder(lineWidth: 3, antialiased: true)
                .foregroundColor(isEnabled ? config.color : .myTertiary)
                .opacity(config.isHovered || isPressed || !config.incognitoUnderline ? 1 : 0)
                .animation(.easeOut, value: isEnabled)
        }
    }
}

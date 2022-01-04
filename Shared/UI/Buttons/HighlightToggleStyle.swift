// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct HighlightToggleStyle: ToggleStyle {

    var off: String
    var on: String
    var offColor: Color = .myHighlight
    var onColor: Color = .myHighlight
    var font: Font = .title3
    @Namespace private var toggle

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            Option(label: off, color: offColor, isOn: !configuration.isOn, set: { configuration.isOn = false })
            Option(label: on, color: onColor, isOn: configuration.isOn, set: { configuration.isOn = true })
        }
        .font(font)
        .environment(\.namespace, toggle)
        .animation(.spring().speed(2), value: configuration.isOn)
    }

    struct Option: View {

        var label: String
        var color: Color
        var isOn: Bool
        var set: () -> Void
        @Environment(\.namespace) private var namespace

        var body: some View {
            Button(action: set) {
                Text(label)
                    .fontWeight(isOn ? .semibold : .medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

            }
                .buttonStyle(HoverButtonStyle(anchor: .bottom, inactiveColor: isOn ? .myHighlight : nil))
                .background(background, alignment: .bottom)
                .onTapGesture { set() }
        }

        @ViewBuilder private var background: some View {
            if isOn {
                RoundedRectangle(cornerRadius: 1.5)
                    .frame(height: 3)
                    .foregroundColor(color)
                    .matchedGeometryEffect(id: "toggle", in: namespace!)
            }
        }
    }
}

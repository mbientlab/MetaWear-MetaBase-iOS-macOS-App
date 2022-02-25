// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct HighlightToggleStyle: ToggleStyle {

    var off: String
    var on: String
    var offColor: Color = .myHighlight
    var onColor: Color = .myHighlight
    var font: Font.Config = .ctaMajor.adjustingSize(steps: idiom == .iPhone ? -2 : -1)
    var padding: CGFloat = 6
    @Namespace private var toggle

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: max(0, 10 - padding)) {
            Option(label: off,
                   color: offColor,
                   isOn: !configuration.isOn,
                   set: { configuration.isOn = false },
                   font: font,
                   padding: padding
            )
            Option(label: on,
                   color: onColor,
                   isOn: configuration.isOn,
                   set: { configuration.isOn = true },
                   font: font,
                   padding: padding
            )
        }
        .environment(\.namespace, toggle)
        .animation(.spring().speed(2), value: configuration.isOn)
    }

    struct Option: View {

        internal init(symbol: SFSymbol, color: Color, isOn: Bool, set: @escaping () -> Void, font: Font.Config, padding: CGFloat = 6) {
            self.label = AnyView(symbol.image())
            self.color = color
            self.isOn = isOn
            self.set = set
            self.font = font
            self.padding = padding
        }

        internal init(label: String, color: Color, isOn: Bool, set: @escaping () -> Void, font: Font.Config, padding: CGFloat = 6) {
            self.label = AnyView(
                Text(label)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
            )
            self.color = color
            self.isOn = isOn
            self.set = set
            self.font = font
            self.padding = padding
        }

        var label: AnyView
        var color: Color
        var isOn: Bool
        var set: () -> Void
        var font: Font.Config
        var padding: CGFloat = 6
        @Environment(\.namespace) private var namespace
        @Namespace private var fallbackNamespace
        
        var body: some View {
            Button(action: set) {
                label
                    .adaptiveFont(font.bumpWeight(isOn))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .padding(padding)
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
                    .matchedGeometryEffect(id: "toggle", in: namespace ?? fallbackNamespace)
            }
        }
    }
}

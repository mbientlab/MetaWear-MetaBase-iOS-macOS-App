// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public struct CrossPlatformStylizedMenu<L: Listable>: View {

    public init(selected: Binding<L>,
                options: [L],
                labelFont: Font? = nil,
                labelColor: Color,
                staticLabel: String? = nil) {
        _selected = selected
        self.options = options
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.staticLabel = staticLabel
    }

    @Binding public var selected: L
    public let options: [L]
    public var labelFont: Font? = nil
    public var labelColor: Color
    public var staticLabel: String?

    public var body: some View {
        menu
    }

    private var menu: some View {
        Menu {
            ForEach(options) { option in
                Button(action: { selected = option }, label: { Text(option.label) })
            }
        } label: {
            Text(staticLabel ?? selected.label)
                .foregroundColor(labelColor)
                .font(labelFont)
                .accessibilityLabel(selected.label)
        }
#if os(macOS)
        .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
#endif
        .alignmentGuide(HorizontalAlignment.center) { $0[HorizontalAlignment.center] + 5 }
        .background(tickMark.alignmentGuide(.trailing) { $0[.leading] + 3 }, alignment: .trailing)
    }

    private var tickMark: some View {
        Text("􀆈")
            .font(labelFont)
            .scaleEffect(0.7)
            .foregroundColor(labelColor)
            .accessibilityHidden(true)
    }

    private var picker: some View {
        Picker(selection: $selected) {
            ForEach(options) { option in
                Text(option.label).id(option).tag(option)
            }
        } label: {
            Text("")
        }
        .pickerStyle(.menu)
    }
}

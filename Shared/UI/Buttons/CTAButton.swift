// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct CTAButton: View {

    init(_ cta: String,
         _ symbol: SFSymbol? = nil,
         hover: Color = .myHighlight,
         base: Color = .myPrimary,
         maxWidth: CGFloat? = nil,
         action: @escaping () -> Void) {
        self.symbol = symbol
        self.cta = cta
        self.action = action
        self.hover = hover
        self.base = base
        self.maxWidth = maxWidth
    }

    let cta: String
    let symbol: SFSymbol?
    let action: () -> Void
    let hover: Color
    let base: Color
    let maxWidth: CGFloat?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false
    @Namespace private var namespace

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let symbol = symbol {
                    symbol.image()
                }

                Text(cta)
            }
                .font(.title2.weight(scheme == .light ? .medium : .medium))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(isHovered ? hover : base)

                .padding(.horizontal, 25)
                .padding(.vertical, 8)
                .frame(minWidth: 150, maxWidth: maxWidth, alignment: .center)
                .whenHovered { isHovered = $0 }
        }
        .buttonStyle(UnderlinedButtonStyle(color: hover, isHovered: isHovered))
        .animation(.spring(), value: isHovered)
        .opacity(isEnabled ? 1 : 0.35)

#if os(macOS)
        .controlSize(.large)
#endif
    }
}

struct MinorCTAButton: View {

    let cta: String
    let action: () -> Void
    let bg: Color
    let text: Color
    let maxWidth: CGFloat?

    init(_ cta: String,
         bg: Color = .myGroupBackground,
         text: Color = .myPrimary,
         maxWidth: CGFloat? = nil,
         action: @escaping () -> Void) {
        self.cta = cta
        self.action = action
        self.bg = bg
        self.text = text
        self.maxWidth = maxWidth
    }

    var body: some View {
        Button(action: action) {
            Text(cta)
                .font(.headline)
                .foregroundColor(text)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 90, maxWidth: maxWidth, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(bg)
                )
        }
        .buttonStyle(HoverButtonStyle())
    }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct CTAButton: View {

    init(_ cta: String,
         _ symbol: SFSymbol? = nil,
         hover: Color = .myHighlight,
         base: Color = .myPrimary,
         maxWidth: CGFloat? = nil,
         padding: CGFloat = 6,
         style: Style = .major,
         action: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.cta = cta
        self.action = action
        self.hover = hover
        self.base = base
        self.maxWidth = maxWidth
        self.padding = padding
        self.font = style.font
        self.incognito = style == .minor
        self.hPadding = style == .minor ? 12 : 25
        self.vPadding = 8
        self.style = style
    }

    let cta: String
    let symbol: SFSymbol?
    let action: () -> Void
    let hover: Color
    let base: Color
    let maxWidth: CGFloat?
    let padding: CGFloat
    let font: Font
    let incognito: Bool
    let hPadding: CGFloat
    let vPadding: CGFloat
    let style: Style

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
                .font(font.weight(scheme == .light ? .medium : .medium))
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(isHovered && style != .minor ? hover : base)

                .padding(.horizontal, hPadding)
                .padding(.vertical, vPadding)
                .padding(padding)
                .frame(minWidth: 150, maxWidth: maxWidth, alignment: .center)
                .whenHovered { isHovered = $0 }
        }
        .buttonStyle(UnderlinedButtonStyle(color: hover,
                                           isHovered: isHovered,
                                           incognitoUnderline: incognito))
        .animation(.spring(), value: isHovered)
        .opacity(isEnabled ? 1 : 0.35)

#if os(macOS)
        .controlSize(.large)
#endif
    }

    enum Style {
        case major
        case minor

        var font: Font {
            switch self {
                case .major: return .title2
                case .minor: return .headline
            }
        }
    }
}

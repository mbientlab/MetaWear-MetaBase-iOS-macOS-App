// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct CTAButton: View {

    let cta: String
    let action: () -> Void
    let bg: Color
    let text: Color
    let maxWidth: CGFloat?

    @Environment(\.colorScheme) var scheme

    init(_ cta: String,
         bg: Color = .accentColor,
         text: Color = .myBackground,
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
                .fontWeight(scheme == .light ? .medium : .medium)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .frame(minWidth: 140, maxWidth: maxWidth, alignment: .center)
#if os(iOS)
                .background(
                    Capsule(style: .continuous)
                        .fill(bg)
                )
#endif
        }
#if os(iOS)
        .buttonStyle(.borderless)
#else
        .buttonStyle(.bordered)
#endif
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
        .buttonStyle(.borderless)
    }
}

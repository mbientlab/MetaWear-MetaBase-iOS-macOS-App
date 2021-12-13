// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct CTAButton: View {

    let cta: String
    let action: () -> Void
    let bg: Color
    let text: Color
    let maxWidth: CGFloat?

    init(_ cta: String,
         bg: Color = .black.opacity(0.1),
         text: Color = .white,
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
         bg: Color = .white.opacity(0.15),
         text: Color = .white,
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

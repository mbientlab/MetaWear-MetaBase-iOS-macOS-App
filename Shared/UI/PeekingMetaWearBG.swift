// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct PeekingMetaWearBG: ViewModifier {

    let size: CGFloat = 400

    func body(content: Content) -> some View {
        content
            .background(Modifier(alignment: .leading, size: size), alignment: .center) // Right
            .background(Modifier(alignment: .trailing, size: size), alignment: .center) // Left
    }

    struct Modifier: View {

        let alignment: HorizontalAlignment
        let size: CGFloat

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.colorScheme) private var scheme
        private var metaWearOpacity: CGFloat { scheme == .light ? 0.6 : 0.73 }
        private var isOnRightSignum: Double { alignment == .leading ? 1 : -1 }
        @State private var isHovered = false

        var body: some View {
            MetaWearWithLED(width: size, height: size)
                .opacity(metaWearOpacity)
                .whenHovered { isHovered = $0 }
                .alignmentGuide(HorizontalAlignment.center) {
                    $0[alignment] + (isHovered ? 50 * -isOnRightSignum : 0)
                }
                .rotationEffect(isHovered ? .degrees(11 * isOnRightSignum) : .degrees(0))
                .animation(.spring(response: 0.8, dampingFraction: 0.65, blendDuration: 1), value: isHovered)
                .allowsHitTesting(!reduceMotion)
                .disabled(reduceMotion)
        }
    }
}

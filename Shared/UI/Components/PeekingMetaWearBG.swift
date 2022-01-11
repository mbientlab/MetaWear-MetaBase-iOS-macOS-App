// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

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
        @GestureState private var drag: CGSize = .zero
        private var isDragging: Bool { drag != .zero }

        private let peekEffectSize: CGFloat = idiom.is_Mac ? 50 : 10
        private let rotateEffectSize: CGFloat = idiom.is_Mac ? 11 : 5

        var body: some View {
            MetaWearWithLED(width: size, height: size)
                .opacity(metaWearOpacity)

                .whenHovered { isHovered = $0 }
            #if os(iOS)
                .contentShape(Rectangle())
                .gesture(dragGesture())
            #endif

                .alignmentGuide(HorizontalAlignment.center) {
                    $0[alignment] + (isHovered || isDragging ? peekEffectSize * -isOnRightSignum : 0)
                }
                .rotationEffect(isHovered || isDragging ? .degrees(rotateEffectSize * isOnRightSignum) : .degrees(0))
                .offset(drag)
                .animation(.spring(response: 0.8, dampingFraction: 0.65, blendDuration: 1), value: isHovered)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.25), value: drag)
                .allowsHitTesting(!reduceMotion)
                .disabled(reduceMotion)
        }

        private func dragGesture() -> GestureStateGesture<DragGesture, CGSize> {
            DragGesture()
                .updating($drag) { value, state, _ in
                    state = value.translation.clamped(radius: 90)
                }
            }
    }
}

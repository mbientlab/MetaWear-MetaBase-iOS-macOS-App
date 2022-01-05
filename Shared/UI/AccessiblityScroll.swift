// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

public extension View {
    func scrollAtAccessibilitySize(
        threshold: ContentSizeCategory? = nil,
        axis: Axis.Set = .vertical
    ) -> some View {
        modifier(AccessibilityScroll(threshold: threshold, axis: axis))
    }
}

private struct AccessibilityScroll: ViewModifier {

    var threshold: ContentSizeCategory?
    var axis: Axis.Set

    func body(content: Content) -> some View {
        Modifier(content: content, config: self)
    }

    private struct Modifier: View {

        let content: Content
        let config: AccessibilityScroll

        var body: some View {
            if isAccessibilitySize {
                ScrollView(config.axis) { content }
            } else {
                content
            }
        }

        @Environment(\.sizeCategory) private var typeSize
        private var isAccessibilitySize: Bool {
            if let threshold = config.threshold {
                return typeSize >= threshold
            } else {
                return typeSize.isAccessibilityCategory
            }
        }
    }
}

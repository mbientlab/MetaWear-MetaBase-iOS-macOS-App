// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension Onboarding {

    struct ItemBox: View {

        let item: OnboardingVM.Item
        private let spacing: CGFloat = 15

        var body: some View {
            VStack(alignment: .leading, spacing: spacing) {
                HStack(alignment: .center, spacing: spacing) {
                    symbol

                    Text(item.headline)
                        .adaptiveFont(.onboardingHeadline)
                }
                .foregroundColor(item.color)

                HStack(spacing: spacing) {
                    symbol.hidden()

                    Text(item.description)
                        .adaptiveFont(.onboardingDescription)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.mySecondary)
                        .lineSpacing(5)
                }
            }
        }

        private var symbol: some View {
            item.symbol.image()
                .adaptiveFont(.onboardingHeadline.withWeight(.semibold))
        }
    }


    struct PanelBG: View {

        @Environment(\.reverseOutColor) private var reverseOutColor
        @Environment(\.colorScheme) private var scheme
        private var isLight: Bool { scheme == .light }

        let shape = RoundedRectangle(cornerRadius: 12)

        var body: some View {
            if #available(macOS 12.0, iOS 15.0, *) {
                ZStack {
                    fill.opacity(isLight ? 0 : 0.8)
                    stroke
                }
                .background(isLight ? .ultraThinMaterial : .regularMaterial)
                .clipShape(shape)
                .shadow(color: .black.opacity(isLight ? 0.08 : 0.25), radius: 8, x: 2, y: 2)

            } else {
                ZStack {
                    fill
                    stroke
                }
            }
        }

        var fill: some View {
            shape
                .foregroundColor(reverseOutColor)
                .brightness(0.03)
        }

        var stroke: some View {
            shape
                .stroke(lineWidth: 2)
                .foregroundColor(.myTertiary.opacity(0.15))
        }
    }
}

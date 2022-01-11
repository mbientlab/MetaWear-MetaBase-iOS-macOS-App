// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct Onboarding: View {

    init(factory: UIFactory) {
        _importer = .init(wrappedValue: factory.makeImportVM())
    }

    @StateObject var importer: ImportSessionsVM
    @StateObject var vm = OnboardingVM()
    @EnvironmentObject private var factory: UIFactory
    @Environment(\.sizeCategory) private var typeSize
    private var isAccessibilitySize: Bool { typeSize.isAccessibilityCategory }
    private var centerColumnWidth: CGFloat { isAccessibilitySize ? .infinity : 450 }

    private var flipIntroImport: Binding<Bool> {
        Binding(get: { vm.focus != .importer },
                set: { shouldShowIntro in
            if shouldShowIntro { vm.setFocus(.intro) }
            else { vm.setFocus(.importer) }
        })
    }

    var body: some View {
        VStack(alignment: .center, spacing: isAccessibilitySize ? 20 : 45) {
            title
            FlipView(up: items,
                     down: importStatus,
                     showFaceUp: flipIntroImport)
                .modifier(PeekingMetaWearBG())
            ctas
        }
        .padding(.bottom, 45)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundToEdges(.defaultSystemBackground)
        .environmentObject(importer)
    }

    private var title: some View {
        Text(vm.title)
            .adaptiveFont(.onboardingLargeTitle)
            .padding(.bottom, isAccessibilitySize ? 20 : 0)
    }

    private var importStatus: some View {
        VStack(alignment: .center, spacing: 45) {
            ImportSessions.ProgressReport()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(40)
        .background(PanelBG())
        .frame(maxWidth: centerColumnWidth, maxHeight: .infinity, alignment: .leading)
    }

    private var items: some View {
        VStack(alignment: .center, spacing: 45) {
            ForEach(vm.items) { item in
                ItemBox(item: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(40)
        .background(PanelBG())
        .frame(maxWidth: centerColumnWidth, alignment: .leading)
        .scrollAtAccessibilitySize()
    }

    @ViewBuilder private var ctas: some View {
        if vm.showMigrationCTAs {
            ImportSessions.CTAs(
                willStartImport: { vm.setFocus(.importer) },
                skipAction: { vm.setFocus(.complete) },
                successAction: { vm.setFocus(.complete) },
                successCTA: "Start"
            )
                .frame(maxWidth: centerColumnWidth, alignment: .center)
        } else {
            CTAButton("Start", padding: 6,
                      action: { vm.setFocus(.complete) })
        }
    }
}

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

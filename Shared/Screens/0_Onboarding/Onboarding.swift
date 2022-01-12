// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct Onboarding: View {

    init(importer: ImportSessionsVM, vm: OnboardingVM)  {
        _importer = .init(wrappedValue: importer)
        _vm =  .init(wrappedValue: vm)
    }
    @StateObject var vm: OnboardingVM
    @StateObject var importer: ImportSessionsVM

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

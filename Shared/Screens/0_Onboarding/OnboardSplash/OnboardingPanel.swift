// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct OnboardingPanel: View {

    init(importer: MigrateDataPanelVM, vm: OnboardingVM)  {
        _importer = .init(wrappedValue: importer)
        _vm =  .init(wrappedValue: vm)
    }
    @StateObject private var vm: OnboardingVM
    @StateObject private var importer: MigrateDataPanelVM

    #if os(iOS)
    private var width: CGFloat { .init(iPhone: UIScreen.main.bounds.width * 0.95, 450) }
    #else
    private let width: CGFloat = 450
    #endif

    var body: some View {
        FocusFlipPanel(
            vm: vm.focus,
            centerColumnNominalWidth: width,
            macOSHostWindowPrefix: Windows.onboarding.tag
        ) { maxWidth in
            if idiom == .iPhone {
                ScrollView {
                    ItemsPanel(items: vm.content.items, maxWidth: maxWidth)
                }
            } else {
                ItemsPanel(items: vm.content.items, maxWidth: maxWidth)
                    .scrollAtAccessibilitySize()
            }
        } down: { maxWidth in
            MigrateDataPanel.ProgressReportPane(maxWidth: maxWidth)
        } cta: { cta }
#if os(iOS)
        .padding(.top, 50)
#endif
        .onAppear(perform: vm.onAppear)
        .environmentObject(vm)
        .environmentObject(importer)
    }

    @ViewBuilder private var cta: some View {
        if vm.showMigrationCTAs {
            MigrateDataPanel.CTAs(
                willStartImport: { vm.focus.setFocus(.importer) },
                skipAction: { vm.focus.setFocus(.complete) },
                successAction: { vm.focus.setFocus(.complete) },
                successCTA: vm.completionCTA
            )
        } else {
            CTAButton(vm.completionCTA, padding: 6, action: { vm.focus.setFocus(.complete) })
        }
    }
}

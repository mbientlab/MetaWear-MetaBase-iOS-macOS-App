// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct OnboardingPanel: View {

    init(importer: MigrateDataPanelVM, vm: OnboardingVM)  {
        _importer = .init(wrappedValue: importer)
        _vm =  .init(wrappedValue: vm)
    }
    @StateObject var vm: OnboardingVM
    @StateObject var importer: MigrateDataPanelVM

    var body: some View {
        FocusFlipPanel(vm: vm.focus) { maxWidth in
            ItemsPanel(items: vm.content.items, maxWidth: maxWidth)
        } down: { maxWidth in
            ImportStatus(maxWidth: maxWidth)
        } cta: { cta }
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

extension OnboardingPanel {

    struct ImportStatus: View {
        var maxWidth: CGFloat
        var body: some View {
            VStack(alignment: .center, spacing: 45) {
                MigrateDataPanel.ProgressReport()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(40)
            .background(ItemsPanel.PanelBG())
            .frame(maxWidth: maxWidth, maxHeight: .infinity, alignment: .leading)
        }
    }
}

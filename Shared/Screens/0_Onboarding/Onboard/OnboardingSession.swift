// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension Color {
#if os(macOS)
    static let lightModeFaintBG = Color(.windowBackgroundColor)
#else
    static let lightModeFaintBG = Color(.secondarySystemBackground)
#endif
}

struct OnboardingSession: View {

    init(importer: MigrateDataPanelVM, vm: OnboardingSessionVM)  {
        _importer = .init(wrappedValue: importer)
        _vm =  .init(wrappedValue: vm)
    }
    @StateObject private var vm: OnboardingSessionVM
    @StateObject private var importer: MigrateDataPanelVM
    @Environment(\.colorScheme) private var colorScheme

    #if os(iOS)
    private var width: CGFloat { .init(iPhone: UIScreen.main.bounds.width * 0.95, 450) }
    #else
    private let width: CGFloat = 450
    #endif

    private var background: Color { colorScheme == .light ? .lightModeFaintBG : .defaultSystemBackground }

    var body: some View {
        FocusFlipPanel(
            vm: vm.focus,
            centerColumnNominalWidth: width,
            macOSHostWindowPrefix: Windows.onboarding.tag,
            background: background
        ) { maxWidth in
            makeItemsPanel(maxWidth)
        } down: { maxWidth in
            MigrationSession.ProgressReportPane(maxWidth: maxWidth)
        } cta: { cta }
        .padding(.top, .init(macOS: 25, iOS: 50))
        .background(background.edgesIgnoringSafeArea(.all))
        .onAppear(perform: vm.onAppear)
        .environmentObject(vm)
        .environmentObject(importer)
        .onDisappear(perform: vm.markDidOnboard)
    }

    @ViewBuilder private func makeItemsPanel(_ maxWidth: CGFloat) -> some View {
        if idiom == .iPhone {
            ScrollView {
                ItemsPanel(items: vm.content.items, maxWidth: maxWidth)
            }
        } else {
            ItemsPanel(items: vm.content.items, maxWidth: maxWidth)
                .scrollAtAccessibilitySize()
        }
    }

    @ViewBuilder private var cta: some View {
        if vm.showMigrationCTAs {
            MigrationSession.CTAs(
                willStartImport: { [weak vm] in vm?.focus.setFocus(.importer) },
                skipAction: { [weak vm] in vm?.focus.setFocus(.complete) },
                successAction: { [weak vm] in vm?.focus.setFocus(.complete) },
                successCTA: vm.completionCTA
            )
        } else {
            CTAButton(vm.completionCTA, padding: 6, action: { [weak vm] in vm?.focus.setFocus(.complete) })
        }
    }
}

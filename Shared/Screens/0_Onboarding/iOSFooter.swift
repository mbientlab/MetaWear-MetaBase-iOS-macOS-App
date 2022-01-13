// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct iOSFooter: View {

    @EnvironmentObject private var factory: UIFactory
    @Environment(\.openURL) private var open

    @State private var showMigrationSheet = false
    @State private var showOnboardingSheet = false

    @State private var showButtons = false
    @State private var showMigrationButton = false

    @AppStorage(wrappedValue: 0.0, UserDefaults.MetaWear.Keys.didOnboardAppVersion) private var lastOnboardVersion
    @AppStorage(wrappedValue: 0, UserDefaults.MetaWear.Keys.launchCount) private var launchCount
    private var showOnboardingSheetButton: Bool {
        lastOnboardVersion < CurrentMetaBaseVersion || launchCount < 3
    }
    private var hasNotOnboarded: Bool {
        lastOnboardVersion < CurrentMetaBaseVersion
    }

    var body: some View {
        content
            .onReceive(factory.getDidImportState()) { showMigrationButton = $0 == false }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeIn, value: showButtons)
            .onAppear { DispatchQueue.main.after(2) { showButtons = true } }
    }

    // MARK: - Composition

    private var content: some View {
        HStack(spacing: 50) {
            if showOnboardingSheetButton { new }
            if showMigrationButton { migrate }
        }
        .foregroundColor(.mySecondary)
        .adaptiveFont(.hLabelSubheadline)
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear { if hasNotOnboarded { showOnboardingSheet = true } }
        .onChange(of: lastOnboardVersion) { showOnboardingSheet = $0 < CurrentMetaBaseVersion }
#if DEBUG
        .overlay(Menu("Debug") { DebugMenu() }
                    .opacity(0.5)
                    .menuStyle(.borderlessButton),
                 alignment: .trailing)
#endif
        .padding(.screenInset)
    }

    // MARK: - Buttons

    private var new: some View {
        Button("What's New?") { showOnboardingSheet = true }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingPanel(importer: factory.makeImportVM(), vm: factory.makeOnboardingVM())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var migrate: some View {
        Button("Migrate Data") { showMigrationSheet = true }
        .sheet(isPresented: $showMigrationSheet) {
            MigrateDataPanel(importer: factory.makeImportVM(), vm: factory.makeMigrationVM())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

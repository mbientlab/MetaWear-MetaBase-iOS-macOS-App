// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct OnboardingFooter_iOS: View {

    @EnvironmentObject private var factory: UIFactory
    @State private var showButtons = false

    var body: some View {
        HStack(spacing: 50) {
            OnboardingControl()
            MigrationControl()
        }
        .foregroundColor(.mySecondary)
        .adaptiveFont(.hLabelSubheadline)
        .frame(maxWidth: .infinity, alignment: .center)

//#if DEBUG
//        .overlay(Menu("Debug") { DebugMenu() }
//                    .opacity(0.5)
//                    .menuStyle(.borderlessButton),
//                 alignment: .trailing)
//#endif
        .padding(.screenInset)
        .opacity(showButtons ? 1 : 0)
        .animation(.easeIn, value: showButtons)
        .onAppear { DispatchQueue.main.after(2) { showButtons = true } }
    }
}

extension OnboardingFooter_iOS {

    struct OnboardingControl: View {
        @EnvironmentObject private var factory: UIFactory
        @State private var showSheet = false

        var body: some View {
            ZStack {
                if showButton { button }
            }
            .onAppear { if hasNotOnboarded { showSheet = true } }
            .onChange(of: lastOnboardedVersion) { showSheet = $0 < CurrentMetaBaseVersion }
        }

        private var button: some View {
            Button("What's New?") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                OnboardingPanel(importer: factory.makeImportVM(), vm: factory.makeOnboardingVM())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        private var showButton:      Bool { hasNotOnboarded || launchCount < 3 }
        private var hasNotOnboarded: Bool { lastOnboardedVersion < CurrentMetaBaseVersion }
        @AppStorage(wrappedValue: 0.0, Self.keyOnboard)  private var lastOnboardedVersion
        @AppStorage(wrappedValue: 0,   Self.keyLaunches) private var launchCount
        private static let keyOnboard  = UserDefaults.MetaWear.Keys.didOnboardAppVersion
        private static let keyLaunches = UserDefaults.MetaWear.Keys.launchCount

    }

    struct MigrationControl: View {

        @EnvironmentObject private var factory: UIFactory
        @State private var showSheet = false
        @State private var showButton = true

        var body: some View {
            ZStack {
                if showButton { button }
            }
            .onReceive(factory.getDidImportState()) { showButton = $0 == false }
        }

        private var button: some View {
            Button("Migrate Data") { showSheet = true }
            .sheet(isPresented: $showSheet) {
                MigrateDataPanel(importer: factory.makeImportVM(), vm: factory.makeMigrationVM())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#if os(macOS)
struct OnboardingLauncher_macOS: View {

    @AppStorage(wrappedValue: 0.0, UserDefaults.MetaWear.Keys.didOnboardAppVersion) private var lastOnboardVersion
    @Environment(\.openURL) private var open

    var body: some View {
        Color.clear.hidden()
            .onAppear {
                guard lastOnboardVersion < CurrentMetaBaseVersion else { return }

                for window in NSApp.windows {
                    guard let id = window.identifier?.rawValue else { continue }
                    if id.hasPrefix(Windows.onboarding.tag) {
                        window.makeKeyAndOrderFront(nil)
                        return
                    }
                }
                // Resort to SwiftUI open only if there isn't an existing window for that identifier
                open.callAsFunction(Windows.onboarding.externalEventURL)
            }
    }
}
#endif

// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

struct OnboardingFooter_iOS: View {

    @State private var showButtons = false

    var body: some View {
        HStack(spacing: 50) {
            OnboardingControl()
            MigrationControl()
        }
        .foregroundColor(.mySecondary)
        .adaptiveFont(.hLabelSubheadline)
        .frame(maxWidth: .infinity, alignment: .center)

#if DEBUG
        .overlay(Menu("􀌛") { DebugMenu() }
                    .opacity(0.25)
                    .menuStyle(.borderlessButton),
                 alignment: .trailing)
#endif
        .padding(.screenInset)
        .opacity(showButtons ? 1 : 0)
        .animation(.easeIn, value: showButtons)
        .onAppear { DispatchQueue.main.after(2) { showButtons = true } }
    }
}

extension OnboardingFooter_iOS {

    struct OnboardingControl: View {

        @EnvironmentObject private var state: OnboardState
        @EnvironmentObject private var factory: UIFactory
        @State private var showSheet = false

        var body: some View {
            button
                .onAppear {
                    guard state.didOnboard == false else { return }
                    DispatchQueue.main.after(0.5) {
                        showSheet = true
                    }
                }
                .onChange(of: state.didOnboard) { didOnboard in
                    if !showSheet && didOnboard == false { showSheet = true }
                }
        }

        @ViewBuilder private var button: some View {
            if state.didOnboard == false || state.launches < 3 {
                Button("What's New?") { showSheet = true }
                .sheet(isPresented: $showSheet) {
                    OnboardingSession(importer: factory.makeImportVM(), vm: factory.makeOnboardingSessionVM())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    struct MigrationControl: View {

        @EnvironmentObject private var state: OnboardState
        @EnvironmentObject private var factory: UIFactory
        @State private var showSheet = false

        var body: some View {
            button
        }

        @ViewBuilder private var button: some View {
            if state.canMigrate {
                Button("Migrate Data") { showSheet = true }
                .sheet(isPresented: $showSheet) {
                    MigrationSession(importer: factory.makeImportVM(), vm: factory.makeMigrationVM())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

#if os(macOS)
struct OnboardingLauncher_macOS: View {

    @EnvironmentObject var state: OnboardState
    @Environment(\.openURL) private var open

    var body: some View {
        Color.clear.hidden()
            .onAppear {
                guard state.didOnboard == false else { return }

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

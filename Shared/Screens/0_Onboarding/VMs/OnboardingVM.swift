// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI

public class OnboardingVM: ObservableObject {

    @Published private(set) var focus: Focus
    let showMigrationCTAs: Bool

    let items: [Item]

    @Published private(set) var title: String
    private let onboardingTitle: String
    private let importTitle = "Migrate Data"

    struct Item: Identifiable {
        var id: String { headline }
        let symbol: SFSymbol
        let headline: String
        let description: String
        let color: Color
    }

    init(initialState: Focus) {
        self.showMigrationCTAs = true
        self.focus = initialState

        switch initialState {
            case .intro:
                (self.onboardingTitle, self.items) = showMigrationCTAs
                ? Self.makeMetaBase4MigrationContent()
                : Self.makeNewToMetaBaseContent()

                self.title = onboardingTitle

            case .importer:
                (self.onboardingTitle, self.title) = (importTitle, importTitle)
                self.items = []

            case .complete:
                (self.onboardingTitle, self.title) = ("", "")
                self.items = []
        }
    }

    func setFocus(_ destination: Focus) {
        self.focus = destination
        if destination == .intro { title = onboardingTitle }
        if destination == .importer { title = importTitle }
        if destination == .complete { completeOnboarding() }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(CurrentMetaBaseVersion, forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion)
        NSUbiquitousKeyValueStore.default.set(CurrentMetaBaseVersion, forKey: UserDefaults.MetaWear.Keys.didOnboardAppVersion)
#if os(macOS)
        closeAndFadeWindow()
#endif
    }

#if os(macOS)
    func closeAndFadeWindow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            guard let key = NSApp.keyWindow else { return  }
            key.animator().alphaValue = 0
        }) { NSApp.keyWindow?.close() }
    }
#endif

    public enum Focus {
        case intro
        case importer
        case complete
    }
}

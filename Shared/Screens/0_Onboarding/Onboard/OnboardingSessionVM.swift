// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import Combine

public class OnboardingSessionVM: ObservableObject {

    public let content: Content

    // State
    private(set) lazy var focus = FocusPanelVM(initialFocus: Focus.intro, title: title(for:))
    public let completionCTA: String
    public let showMigrationCTAs: Bool
    private var focusUpdate: AnyCancellable? = nil
    private unowned let defaults: UserDefaultsContainer

    public init(didOnboard: Bool, canMigrate: Bool, launchCounter: LocalLaunchCounter, defaults: UserDefaultsContainer) {
        self.defaults = defaults
        self.content = canMigrate ? .migrateMB4Content : .newUserContent
        self.completionCTA = didOnboard ? "Ok" : "Start"
        self.showMigrationCTAs = canMigrate

        if didOnboard == false,
           launchCounter.launches > 1 {
            launchCounter.resetLaunches()
        }
    }
}

public extension OnboardingSessionVM {

    func onAppear() {
        focusUpdate = focus.$focus
            .sink { [weak self] nextFocus in
                switch nextFocus {
                    case .intro:
                        self?.focus.setShowPrimaryPane(true)

                    case .importer:
                        self?.focus.setShowPrimaryPane(false)

                    case .complete:
                        self?.markDidOnboard()
                        self?.focus.dismissPanel.send()
                }
            }
    }

    func markDidOnboard() {
        defaults.local.didOnboardAppVersion = CurrentMetaBaseVersion
        defaults.cloud.didOnboardAppVersion = CurrentMetaBaseVersion
    }

    enum Focus: String, FlipPanelFocus, IdentifiableByRawValue {
        case intro
        case importer
        case complete

        public func next() -> Self {
            switch self {
                case .intro: return .importer
                case .importer: return .complete
                case .complete: return .complete
            }
        }

        public func previous() -> Self {
            switch self {
                case .intro: return .intro
                case .importer: return .intro
                case .complete: return .intro
            }
        }

    }
}

private extension OnboardingSessionVM {

    func title(for focus: Focus) -> String {
        switch focus {
            case .intro: return content.introTitle
            case .importer: return content.importTitle
            case .complete: return content.completeTitle
        }
    }
}

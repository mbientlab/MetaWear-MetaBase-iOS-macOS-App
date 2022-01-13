// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import Combine

public class OnboardingVM: ObservableObject {

    public let content: Content

    // State
    private(set) lazy var focus = FocusPanelVM(initialFocus: Focus.intro, title: title(for:))
    public let completionCTA: String
    public let showMigrationCTAs: Bool
    private var focusUpdate: AnyCancellable? = nil

    public init(state: MigrationState, launchCounter: LocalLaunchCounter) {
        print("-> Migration State", Self.self, "canMigrate", state.canMigrate, "didOnboard", state.didOnboard)
        self.content = state.canMigrate ? .migrateMB4Content : .newUserContent
        self.completionCTA = state.didOnboard ? "Ok" : "Start"
        self.showMigrationCTAs = state.canMigrate

        if state.didOnboard == false,
           launchCounter.launches > 2 {
            launchCounter.resetLaunches()
        }
    }
}

public extension OnboardingVM {

    func onAppear() {
        focusUpdate = focus.$focus
            .sink { [weak self] nextFocus in
                switch nextFocus {
                    case .complete:
                        self?.markDidOnboard()
                        self?.focus.dismissPanel.send()
                    default: return
                }
            }
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

private extension OnboardingVM {

    func markDidOnboard() {
        let key = UserDefaults.MetaWear.Keys.didOnboardAppVersion
        UserDefaults.standard.set(CurrentMetaBaseVersion, forKey: key)
        NSUbiquitousKeyValueStore.default.set(CurrentMetaBaseVersion, forKey: key)
    }

    func title(for focus: Focus) -> String {
        switch focus {
            case .intro: return content.introTitle
            case .importer: return content.importTitle
            case .complete: return content.completeTitle
        }
    }
}

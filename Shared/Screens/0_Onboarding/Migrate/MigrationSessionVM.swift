// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import Combine

public class MigrationSessionVM: ObservableObject {

    public let content: Content

    // State
    private(set) lazy var focus = FocusPanelVM(initialFocus: Focus.debrief, title: title(for:))
    public let completionCTA: String
    public let showMigrationCTAs: Bool
    private var focusUpdate: AnyCancellable? = nil
    /// Cause the view to trigger import immediately to show failure reason
    let triggerImporter: Bool

    public init(didOnboard: Bool, canMigrate: Bool) {
        self.content = .metaBase4
        self.completionCTA = didOnboard ? "Ok" : "Start"
        self.showMigrationCTAs = canMigrate

        if canMigrate == false {
            self.triggerImporter = true
            self.focus.setShowPrimaryPane(false)
            self.focus.setFocus(.importer)
        } else {
            self.triggerImporter = false
        }
    }
}

public extension MigrationSessionVM {

    func onAppear() {
        focusUpdate = focus.$focus
            .sink { [weak self] nextFocus in
                switch nextFocus {
                    case .debrief:
                        self?.focus.setShowPrimaryPane(true)

                    case .importer:
                        self?.focus.setShowPrimaryPane(false)

                    case .complete:
                        self?.focus.dismissPanel.send()
                }
            }
    }

    enum Focus: String, FlipPanelFocus, IdentifiableByRawValue {
        case debrief
        case importer
        case complete

        public func next() -> Self {
            switch self {
                case .debrief: return .importer
                case .importer: return .complete
                case .complete: return .complete
            }
        }

        public func previous() -> Self {
            switch self {
                case .debrief: return .debrief
                case .importer: return .debrief
                case .complete: return .debrief
            }
        }
    }

    struct Content {
        let debriefTitle: String
        let importerTitle: String
        let completeTitle: String
        let debrief: [ItemsPanel.Item]

        public static let metaBase4 = Self.init(
            debriefTitle: "MetaBase 4 Migration",
            importerTitle: "Migrating",
            completeTitle: "",
            debrief: [
                .init(
                    symbol: .icloud,
                    headline: "Upgrade to iCloud Sync",
                    description: "Copy the locally-stored MetaBase 4 CSV files to the cloud to read and write on iOS and Mac.",
                    color: .myPrimaryTinted
                ),
                .init(
                    symbol: .icloudSaved,
                    headline: "Initial Sync Time",
                    description: "iCloud servers may take a few minutes to upload thousands of files from this device.",
                    color: .myPrimaryTinted
                ),
                .init(
                    symbol: .delete,
                    headline: "Non-Destructive",
                    description: "After inspecting the migrated data, you can manually delete the MetaBase 4 files in your iOS device's Documents folder.",
                    color: .myPrimaryTinted
                ),
            ]
        )
    }
}

private extension MigrationSessionVM {

    func title(for focus: Focus) -> String {
        switch focus {
            case .debrief: return content.debriefTitle
            case .importer: return content.importerTitle
            case .complete: return content.completeTitle
        }
    }
}
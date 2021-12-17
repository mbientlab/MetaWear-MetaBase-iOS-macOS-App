// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWear
import MetaWearSync

public class RenamePopupPromptController {
    public weak var delegate: RenameDelegate? = nil
    public static var shared = RenamePopupPromptController()

    public init(delegate: RenameDelegate? = nil) {
        self.delegate = delegate
    }
}

public protocol RenameDelegate: AnyObject {
    func userDidRenameMetaWear(mac: MACAddress, newName: String)
    func userDidRenameGroup(id: UUID, newName: String)
}

public extension RenamePopupPromptController {

    /// Validates a MetaWear rename operation and presents relevant popup dialogs before delivering a valid name to the `RenameDelegate`.
    func rename(existingName: String, mac: MACAddress) {
        getNameInputModally(
            prefilledText: existingName,
            primaryLabel: "Rename",
            primaryIsDestructive: false,
            secondaryLabel: "Cancel",
            secondaryIsDestructive: false,
            title: "Rename \(existingName)",
            message: nil,
            primary: { [weak self] text in self?.userDidInput(text, existingName, mac) },
            secondary: { _ in }
        )
    }

    /// Validates a MetaWear rename operation and presents relevant popup dialogs before delivering a valid name to the `RenameDelegate`.
    func rename(existingName: String, group: UUID) {
        getNameInputModally(
            prefilledText: existingName,
            primaryLabel: "Rename",
            primaryIsDestructive: false,
            secondaryLabel: "Cancel",
            secondaryIsDestructive: false,
            title: "Rename \(existingName)",
            message: nil,
            primary: { [weak self] text in self?.delegate?.userDidRenameGroup(id: group, newName: text) },
            secondary: { _ in }
        )
    }
}

// MARK: - Internal

fileprivate extension RenamePopupPromptController {

    func userDidInput(_ text: String, _ existingName: String, _ mac: MACAddress) {
        guard MetaWear.isNameValid(text) else {
            showTryAgainDialog(for: existingName, invalidText: text, mac: mac)
            return
        }
        delegate?.userDidRenameMetaWear(mac: mac, newName: text)
    }

    func showTryAgainDialog(for existingName: String, invalidText: String, mac: MACAddress) {
        let errorMsg = "MetaWear names must be less than \(MetaWear._maxNameLength) alphanumeric characters, underscores, hyphens, or spaces. \"\(invalidText)\" is not a supported name."

        getNameInputModally(
            prefilledText: invalidText,
            primaryLabel: "Rename",
            primaryIsDestructive: false,
            secondaryLabel: "Cancel",
            secondaryIsDestructive: false,
            title: "Rename \(existingName)",
            message: errorMsg,
            primary: { [weak self] text in self?.userDidInput(text, existingName, mac) },
            secondary: { _ in }
        )
    }
}

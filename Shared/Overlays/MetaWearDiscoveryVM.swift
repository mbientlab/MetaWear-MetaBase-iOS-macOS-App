// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import Metadata

/// Handles general presentation of errors and rename requests for previously unknown devices during a connection request.
/// 
public class MetaWearDiscoveryVM: ObservableObject {

    @Published public private(set) var showError: Error? = nil
    @Published public private(set) var showRenamePopupWithName: String? = nil
    @Published public private(set) var showDiagnostics = false

    public init(store: MetaWearStore) {
        #warning("Implement a new discovery process")
//        store.discoveryDelegate = self
    }

    // Privately-called storage
    /// Returns to the MetaWearStore user input for a device name
    private var editingDidEnd: ((String?) -> Void)?

    /// Returns to the MetaWearsStore so it can execute its next action (e.g., try connecting to the next device in the queue)
    private var didDismissError: (()->Void)? = nil

    /// Returns to the MetaWearsStore so it can execute its next action after the user is done interacting with a recovery-mode device
    private var didDismissDiagnostics: (()->Void)? = nil

}

extension MetaWearDiscoveryVM {

    // MARK: - Delegate

    public func showError(_ error: Error, didDismiss: @escaping () -> Void) {
        self.didDismissError = didDismiss
        self.showError = error
    }

    public func showDiagnostics(didDismiss: @escaping () -> Void) {
        self.didDismissDiagnostics = didDismiss
        self.showDiagnostics = true
    }

    public func provideName(forDeviceNamed: String, editingDidEnd: @escaping (String?) -> Void) {
        self.editingDidEnd = editingDidEnd
        self.showRenamePopupWithName = forDeviceNamed
    }

    public func provideNameAfterInvalidInput(forDeviceNamed: String, editingDidEnd: @escaping (String?) -> Void) {
        self.editingDidEnd = editingDidEnd
        self.showRenamePopupWithName = forDeviceNamed
    }

    // MARK: - User Intents Responding to Delegate Actions

    public func userDidInput(text: String) {
        editingDidEnd?(text)
        self.editingDidEnd = nil
        self.showRenamePopupWithName = nil
    }

    public func userDidCancelEditing() {
        editingDidEnd?(nil)
        self.editingDidEnd = nil
        self.showRenamePopupWithName = nil
    }

    public func userDidDismissError() {
        didDismissError?()
        self.didDismissError = nil
        self.showError = nil
    }

    public func userDidDismissDiagnostics() {
        didDismissDiagnostics?()
        self.didDismissDiagnostics = nil
        self.showDiagnostics = false
    }

}

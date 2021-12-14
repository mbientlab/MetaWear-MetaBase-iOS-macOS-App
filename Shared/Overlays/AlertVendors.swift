// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct AlertVendors: View {

    @EnvironmentObject private var discovery: MetaWearDiscoveryVM

    var body: some View {
        Color.clear
            .background(discoveryError)
            .hidden()
    }

    private var discoveryErrorBinding: Binding<Bool> {
        Binding(get: { discovery.showError != nil },
                set: { _ in discovery.userDidDismissError() })
    }
    private var discoveryError: some View {
        Color.clear
            .alert(isPresented: discoveryErrorBinding) {
                Alert(
                    title: Text("Connection Error"),
                    message: Text(discovery.showError?.localizedDescription ?? ""),
                    dismissButton: .default(Text("Ok"), action: discovery.userDidDismissError)
                )
            }
    }

    private var discoveryRenameBinding: Binding<Bool> {
        Binding(get: { discovery.showRenamePopupWithName != nil },
                set: { _ in })
    }
    private var discoveryRename: some View {
        Color.clear
            .onChange(of: discovery.showRenamePopupWithName) { placeholderName in
                guard let name = placeholderName else { return }
                getNameInputModally(
                    prefilledText: name,
                    primaryLabel: "Connect",
                    primaryIsDestructive: false,
                    secondaryLabel: "Cancel",
                    secondaryIsDestructive: false,
                    title: "Connect to MetaWear",
                    message: nil,
                    primary: discovery.userDidInput(text:),
                    secondary: { _ in discovery.userDidCancelEditing() }
                )
            }
    }
}

func getNameInputModally(
    prefilledText: String,
    primaryLabel: String,
    primaryIsDestructive: Bool = false,
    secondaryLabel: String?,
    secondaryIsDestructive: Bool = false,
    title: String,
    message: String?,
    primary: @escaping (String) -> Void,
    secondary: @escaping (String) -> Void)
{
#if canImport(AppKit)
    let alert = NSAlert()
    alert.messageText = title
    if let info = message {
        alert.informativeText = info
    }

    let input = NSTextField(frame: .init(x: 0, y: 0, width: 300, height: 26))
    input.bezelStyle = .roundedBezel
    input.controlSize = .large
    input.alignment = .center
    input.placeholderString = prefilledText
    input.stringValue = prefilledText
    input.isAutomaticTextCompletionEnabled = true
    alert.accessoryView = input


    alert.addButton(withTitle: primaryLabel)

    if primaryIsDestructive {
        alert.buttons.first?.hasDestructiveAction = true
    }

    if let secondary = secondaryLabel {
        alert.addButton(withTitle: secondary)
        if secondaryIsDestructive {
            alert.buttons[1].hasDestructiveAction = true
        }
    }

    guard let window = NSApplication.shared.keyWindow else { return }
    alert.beginSheetModal(for: window) { [weak input] userResponse in
        switch userResponse {
            case .alertFirstButtonReturn: primary(input?.stringValue ?? "")
            case .alertSecondButtonReturn: secondary(input?.stringValue ?? "")
            default: primary("Default")
        }
    }
#else
fatalError()
#endif
}


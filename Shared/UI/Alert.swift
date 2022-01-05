// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

public func alert(
    primaryLabel: String,
    primaryIsDestructive: Bool = false,
    secondaryLabel: String?,
    secondaryIsDestructive: Bool = false,
    title: String,
    message: String?,
    primary: @escaping () -> Void,
    secondary: @escaping () -> Void)
{
#if canImport(AppKit)
    let alert = NSAlert()
    alert.messageText = title
    if let info = message {
        alert.informativeText = info
    }

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
    alert.beginSheetModal(for: window) { userResponse in
        switch userResponse {
            case .alertFirstButtonReturn: primary()
            case .alertSecondButtonReturn: secondary()
            default: primary()
        }
    }
#else
    fatalError()
#endif
}


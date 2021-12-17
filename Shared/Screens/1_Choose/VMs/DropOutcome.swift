// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation

public enum DropOutcome {
    case addToGroup
    case formNewGroup
    case removeFromGroup
    case noDrop

    var label: String {
        switch self {
            case .addToGroup: return "Add"
            case .formNewGroup: return "New Group"
            case .removeFromGroup: return "Remove from Group"
            case .noDrop: return ""
        }
    }
}

import SwiftUI

struct DropOutcomeIndicator: View {

    let outcome: DropOutcome

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white)
                .opacity(outcome == .noDrop ? 0 : 0.1)

            Text(outcome.label)
                .opacity(outcome == .noDrop ? 0 : 1)
                .accessibilityHidden(outcome == .noDrop)
        }
        .animation(.easeOut, value: outcome)
    }
}

protocol DropOutcomeVM: DropDelegate {
    var dropOutcome: DropOutcome { get }
}

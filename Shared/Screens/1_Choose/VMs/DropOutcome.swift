// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import SwiftUI
import MetaWearSync

struct DropOutcomeIndicator: View {

    let outcome: DraggableMetaWear.DropOutcome

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

public extension DraggableMetaWear.DropOutcome {

    var label: String {
        switch self {
            case .addToGroup: return "Add"
            case .newGroup: return "New Group"
            case .deleteFromGroup: return "Remove from Group"
            case .noDrop: return ""
        }
    }
}

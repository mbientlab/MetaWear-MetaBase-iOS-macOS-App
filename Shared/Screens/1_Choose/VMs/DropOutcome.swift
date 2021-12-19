// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWearSync

struct DropOutcomeIndicator: View {

    @Environment(\.dropOutcome) var outcome

    var body: some View {
        Text(outcome.label)
            .lineLimit(0)
            .fixedSize()
            .font(.title.weight(.semibold))
            .foregroundColor(.accentColor)
            .animation(nil, value: outcome)

            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Capsule(style: .continuous).foregroundColor(.yellow))

            .opacity(outcome == .noDrop ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: outcome)
            .accessibilityHidden(outcome == .noDrop)
    }
}

public extension DraggableMetaWear.DropOutcome {

    var label: String {
        switch self {
            case .addToGroup: return "Add"
            case .newGroup: return "Group"
            case .deleteFromGroup: return "Ungroup"
            case .noDrop: return ""
        }
    }
}

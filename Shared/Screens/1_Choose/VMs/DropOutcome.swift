// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Foundation
import mbientSwiftUI
import MetaWearSync

struct OutcomeIndicator: View {

    var outcome: String
    var show: Bool

    var body: some View {
        Text(outcome)
            .lineLimit(0)
            .fixedSize()
            .font(.title.weight(.semibold))
            .foregroundColor(.myBackground)
            .animation(nil, value: outcome)

            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Capsule(style: .continuous).foregroundColor(.myHighlight))

            .opacity(show ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: show)
            .accessibilityHidden(show == false)
    }
}

struct DropOutcomeIndicator: View {

    @Environment(\.dropOutcome) var outcome

    var body: some View {
        OutcomeIndicator(outcome: outcome.label, show: outcome != .noDrop)
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

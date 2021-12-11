// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct LabeledItem<Item:View>: View {

    let label: String
    let item: Item

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            
            Spacer()

            item
                .font(.body.bold().monospacedDigit())
        }
    }
}

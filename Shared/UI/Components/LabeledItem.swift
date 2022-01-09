// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct LabeledItem<Item:View>: View {

    let label: String
    let item: Item

    var body: some View {
        HStack {
            Text(label)
                .adaptiveFont(.hLabelSubheadline)
            
            Spacer()

            item
                .adaptiveFont(.hLabelBody)
        }
    }
}

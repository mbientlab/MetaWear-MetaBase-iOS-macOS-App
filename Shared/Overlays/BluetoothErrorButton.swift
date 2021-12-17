// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

// Scanning toggle
// Show errors if bluetooth is off

struct BluetoothErrorButton: View {

    @EnvironmentObject private var bluetooth: BLEStateVM

    var body: some View {
        if bluetooth.showError {
            Button { bluetooth.didTapCTA() } label: {
                HStack {
                    SFSymbol.error.image()
                    Text(bluetooth.isHovered ? bluetooth.ctaLabelHovered : bluetooth.ctaLabel)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .font(.body.weight(.medium))
            }
            .foregroundColor(.yellow)
            .whenHovered { bluetooth.isHovered = $0 }
            .animation(.easeInOut, value: bluetooth.isHovered)
        }
    }


    struct ToolbarIcon: ToolbarContent {
        var body: some ToolbarContent {
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                BluetoothErrorButton()
                Spacer()
            }
        }
    }

}

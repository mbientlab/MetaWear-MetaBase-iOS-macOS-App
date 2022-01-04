// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

/// Scanning toggle. Shows errors if bluetooth is off.
/// 
struct BluetoothErrorButton: View {

    @EnvironmentObject private var bluetooth: BluetoothStateVM

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
            .foregroundColor(.myFailure)
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

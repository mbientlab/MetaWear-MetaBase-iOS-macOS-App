// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import CoreBluetooth

struct ConnectionButton: View {

    var size: Font = .headline
    var color: Color = .white
    var state: CBPeripheralState

    var body: some View {
        (state == .connected
         ? SFSymbol.connected.image()
         : SFSymbol.disconnected.image() )
            .font(size)
            .foregroundColor(color)
            .animation(.easeOut, value: state)
            .animation(.easeOut, value: color)
            .help(Text(state == .connected ? "Connected" : "Disconnected"))
    }
}

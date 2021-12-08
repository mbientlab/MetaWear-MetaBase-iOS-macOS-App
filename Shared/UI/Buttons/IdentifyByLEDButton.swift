// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import Metadata

struct IdentifyByLEDButton: View {

    var request: () -> Void
    @ObservedObject var emulator: MWLED.FlashPattern.Emulator

    var body: some View {
        Button { request() } label: {
            SFSymbol.led.image()
                .font(.headline)
                .opacity(emulator.ledIsOn ? 1 : 0.75)
                .foregroundColor(emulator.ledIsOn ? .init(emulator.pattern.color) : nil)
        }
        .buttonStyle(.borderless)
        .help("Identify by LED and haptics")
        .animation(.linear(duration: 0.1), value: emulator.ledIsOn)
        .onChange(of: emulator.ledIsOn, perform: { print($0)})
    }
}

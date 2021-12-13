// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear
import MetaWearMetadata

struct IdentifyByLEDButton: View {

    var request: () -> Void
    @ObservedObject var emulator: MWLED.FlashPattern.Emulator

    var body: some View {
        Button { request() } label: {
            SFSymbol.led.image()
                .font(.headline)
                .foregroundColor(emulator.ledIsOn ? .accentColor : nil)
                .padding(4)
                .background(flashingBackground)
        }
        .buttonStyle(.borderless)
        .help("Identify by LED and haptics (if available)")
        .animation(.linear(duration: 0.1), value: emulator.ledIsOn)
    }

    var flashingBackground: some View {
        RoundedRectangle(cornerRadius: 2)
            .foregroundColor(emulator.ledIsOn ? .init(emulator.pattern.color) : .clear)
    }
}

struct IdentifyByLEDLargeButton: View {

    var request: () -> Void
    var isRequesting: Bool
    @ObservedObject var emulator: MWLED.FlashPattern.Emulator

    var body: some View {
        Button { request() } label: {
            if isRequesting { requestingState }
            else { notRequestedState }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.borderless)
        .help("Identify by LED and haptics (if available)")
        .animation(.linear(duration: 0.1), value: emulator.ledIsOn)
        .animation(.linear(duration: 0.1), value: isRequesting)
    }

    var notRequestedState: some View {
        Text("Identify").font(.headline)
    }

    var requestingState: some View {
        SFSymbol.led.image()
            .font(.headline)
            .foregroundColor(.accentColor)
            .padding(4)
            .frame(maxWidth: .infinity)
            .background(flashingBackground)
    }

    var flashingBackground: some View {
        RoundedRectangle(cornerRadius: 2)
            .foregroundColor(emulator.ledIsOn ? .init(emulator.pattern.color) : .clear)
    }
}

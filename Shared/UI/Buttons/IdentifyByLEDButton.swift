// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import MetaWearSync

struct IdentifyByLEDButton: View {

    var flashScale: CGFloat = 1.3
    var request: () -> Void
    @ObservedObject var emulator: MWLED.Flash.Pattern.Emulator

    @State private var isHovering = false
    private var foregroundColor: Color {
        if emulator.ledIsOn { return .myBackground }
        return isHovering ? .myHighlight : .myPrimary
    }

    var body: some View {
        Button { request() } label: {
            SFSymbol.led.image()
                .font(.headline)
                .foregroundColor(foregroundColor)
                .padding(4)
        }
        .whenHovered { isHovering = $0 }
        .buttonStyle(.borderless)
        .background(flashingBackground)
        .help("Identify by LED and haptics (if available)")
        .animation(.linear(duration: 0.1), value: emulator.ledIsOn)
    }

    var flashingBackground: some View {
        Circle().foregroundColor(emulator.ledIsOn ? .init(emulator.pattern.color) : .clear)
            .scaleEffect(flashScale)
    }
}

struct IdentifyByLEDLargeButton: View {

    var request: () -> Void
    var isRequesting: Bool
    @ObservedObject var emulator: MWLED.Flash.Pattern.Emulator

    var body: some View {
        Button { request() } label: {
            if isRequesting { requestingState }
            else { notRequestedState }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(HoverButtonStyle())
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
            .foregroundColor(.myBackground)
            .padding(4)
            .frame(maxWidth: .infinity)
            .background(flashingBackground)
    }

    var flashingBackground: some View {
        RoundedRectangle(cornerRadius: 2)
            .foregroundColor(emulator.ledIsOn ? .init(emulator.pattern.color) : .clear)
    }
}

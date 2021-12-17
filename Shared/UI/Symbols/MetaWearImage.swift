// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import MetaWear
import MetaWearSync

struct MetaWearWithLED: View {

    var width: CGFloat
    var height: CGFloat
    var isLocallyKnown: Bool
    var isHovering: Bool
    var model: MetaWear.Model
    var ledEmulator: MWLED.Flash.Pattern.Emulator = .init(preset: .zero)

    var body: some View {
        model.image.image()
            .resizable()
            .scaledToFill()
            .overlay(FlashingLEDShine(ledEmulator: ledEmulator, diameter: ledDiameter)
                        .offset(x: width * 0.01, y: height * 0.22), alignment: .top)
            .scaleEffect(isHovering ? 1.1 : 1, anchor: .bottom)
            .frame(width: width, height: height, alignment: .center)
            .opacity(isLocallyKnown ? 1 : 0.5)
            .animation(.easeOut, value: isLocallyKnown)
            .animation(.easeOut, value: isHovering)

    }

    private var ledDiameter: CGFloat { min(height, width) * 0.2 }
}

struct FlashingLEDShine: View {

    @ObservedObject var ledEmulator: MWLED.Flash.Pattern.Emulator
    var diameter: CGFloat

    var body: some View {
        ZStack {
            dot.blur(radius: diameter * 0.4)
            dot.blur(radius: diameter * 0.15).opacity(0.5)
        }
    }

    var dot: some View {
        Circle()
            .foregroundColor(.init(ledEmulator.pattern.color))
            .opacity(ledEmulator.ledIsOn ? 1 : 0)
            .animation(.linear(duration: 0.05), value: ledEmulator.ledIsOn)
            .frame(width: diameter, height: diameter)
    }
}

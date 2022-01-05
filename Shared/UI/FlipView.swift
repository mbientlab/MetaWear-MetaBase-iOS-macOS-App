// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct FlipView<Heads: View, Tails: View>: View {

    var up: Heads
    var down: Tails

    @Binding var showFaceUp: Bool
    @State private var isFaceUp = true

    var body: some View {
        ZStack {
            if showFaceUp { upView } else { downView }
        }
        .rotation3DEffect(
            .degrees(showFaceUp ? 180 : 0),
            axis: (x: 0, y: 1, z: 0.0)
        )
        .overlay(FlipReporter(isFaceUp: $isFaceUp, angle: showFaceUp ? 180 : 0))
        .animation(.easeInOut, value: showFaceUp)
    }

    private var upView: some View {
        up.rotation3DEffect(.degrees(isFaceUp ? -180 : 0),
                            axis: (x: 0, y: 1, z: 0.0))
    }

    private var downView: some View {
        down
    }
}

struct FlipReporter: Shape {
    @Binding var isFaceUp: Bool
    var angle: Double
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        DispatchQueue.main.async {
            self.isFaceUp = self.angle >= 90 && self.angle < 270
        }
        return Path()
    }
}

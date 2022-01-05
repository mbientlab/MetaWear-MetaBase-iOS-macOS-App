// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct ProgressSpinnerCircleOutline: View {
    @State private var animate = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(lineWidth: 3)
            .foregroundColor(.myHighlight)
            .rotationEffect(animate ? .degrees(0) : .degrees(360))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate.toggle() }
    }
}

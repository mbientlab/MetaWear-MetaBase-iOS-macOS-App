// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct SpotlightShimmerText<Foreground: View>: View {

    var foreground: Foreground
    var animate: Bool
    var travel: CGFloat

    private let animation = Animation.easeOut(duration: 10)
        .delay(6)
        .repeatForever(autoreverses: false)

    var body: some View {
        ZStack(alignment: .center) {
            foreground
                .foregroundColor(.white.opacity(0.6))

            foreground
                .blendMode(.lighten)
                .mask(mask)
                .animation(animation, value: animate)
        }
    }

    var mask: some View {
        LinearGradient(
            gradient: .init(colors: [
                .white.opacity(0),
                .white,
                .white.opacity(0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
            .frame(width: 80)
            .offset(x: animate ? travel : -travel)
    }
}

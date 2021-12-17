//  © 2021 Ryan Ferrell. github.com/importRyan

import SwiftUI
import mbientSwiftUI

struct MetaWearAtomAnimation: View {

    var animate: Bool
    var size: CGFloat = 90
    var baseOpacity = 0.3
    var color: Color = .white

    private var degrees: Angle { animate ? .degrees(0) : .degrees(18000) }
    private let circleAnimation = Animation
        .linear(duration: 360)
        .repeatForever(autoreverses: false)

    private var path: some View {
        Circle()
        //        MetaWearShape()
            .stroke(lineWidth: size > 50 ? 2 : 1)
            .aspectRatio(1, contentMode: .fit)
    }

    var body: some View {
        ZStack {
            glowInner
            bright
            dim
            dimLarge
            medium
//            glowOuter
        }
        .foregroundColor(color)
    }

    private var glowInner: some View {
        let scaled = size * 0.44
        return Circle()
            .frame(width: scaled, height: scaled)
            .frame(width: size, height: size, alignment: .center)
            .blur(radius: 20)
            .opacity(baseOpacity * 0.3)
            .rotation3DEffect(degrees * 1.5, axis: (x: 0.5, y: 0.5, z: -0.25))
            .animation(circleAnimation.delay(0), value: animate)
    }

    private var bright: some View {
        let scaled = size * 0.44
        return path
            .frame(width: scaled, height: scaled)
            .opacity(baseOpacity * 0.6)
            .rotation3DEffect(degrees * 1.5, axis: (x: 0.5, y: 0.5, z: -0.25))
            .animation(circleAnimation.delay(0), value: animate)
    }

    private var dim: some View {
        let scaled = size * 0.22
        return path
            .frame(width: scaled, height: scaled)
            .opacity(baseOpacity * 0.2)
            .rotation3DEffect(degrees, axis: (x: -0.25, y: -0.25, z: 0.25))
            .animation(circleAnimation.delay(0.05), value: animate)
    }

    private var dimLarge: some View {
        let scaled = size * 1
        return path
            .frame(width: scaled, height: scaled)
            .opacity(baseOpacity * 0.2)
            .rotation3DEffect(degrees * 1.25, axis: (x: 0, y: 1, z: 0.25))
            .animation(circleAnimation.delay(0.15), value: animate)
    }

    private var medium: some View {
        let scaled = size * 0.57
        return path
            .frame(width: scaled, height: scaled)
            .opacity(baseOpacity * 0.4)
            .rotation3DEffect(degrees, axis: (x: 1, y: 0.25, z: 0))
            .animation(circleAnimation.delay(0.3), value: animate)
    }

    private var glowOuter: some View {
        Circle()
            .frame(width: size, height: size)
            .blur(radius: 20)
            .opacity(baseOpacity * 0.4)
            .rotation3DEffect(degrees, axis: (x: 1, y: 0.25, z: 0))
            .animation(circleAnimation.delay(0.3), value: animate)
    }
}

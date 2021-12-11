//  © 2021 Ryan Ferrell. github.com/importRyan

import SwiftUI
import mbientSwiftUI

struct LargeSignalDots: View {

    var signal: SignalLevel
    var dotSize: CGFloat = 15
    var spacing: CGFloat = 4
    var color: Color? = nil

    private var width: CGFloat {
        SignalLevel.maxBarsCG * (dotSize + spacing) - spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(SignalLevel.dots) { dot in
                if dot <= signal { activeDot }
                else { inactiveDot }
            }
        }
        .frame(width: width, height: dotSize)
        .foregroundColor(foreground)
        .animation(.easeOut, value: signal)
    }

    private var inactiveDot: some View {
        Circle()
            .strokeBorder(lineWidth: 2, antialiased: true)
            .frame(width: dotSize, height: dotSize)
            .opacity(0.5)
    }

    private var activeDot: some View {
        Circle()
            .frame(width: dotSize, height: dotSize)
    }

    private var foreground: Color { color ?? .accentColor }
}

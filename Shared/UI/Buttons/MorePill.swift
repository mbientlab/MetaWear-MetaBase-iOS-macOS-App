// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct MorePill: View {

    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                let circleSize = CGFloat(5)
                let pillHeight = circleSize * 3
                let pillWidth = circleSize * 7

                RoundedRectangle(cornerRadius: pillHeight/2)
                    .foregroundColor(isHovered ? .myHighlight : .myTertiary.opacity(0.2))
                    .frame(width: pillWidth, height: pillHeight)

                HStack(spacing: circleSize / 3 * 2) {
                    ForEach(0..<3) { _ in
                        Circle().frame(width: circleSize, height: circleSize)
                            .foregroundColor(isHovered ? .myBackground : .myTertiary.opacity(0.5))
                    }
                }
            }
        }
        .whenHovered { isHovered = $0 }
        .animation(.easeOut.speed(2), value: isHovered)
        .buttonStyle(DepressButtonStyle())
    }
}

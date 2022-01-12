// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct ProgressBar: View  {

    let value: CGFloat
    let progress: Color = .myPrimary
    let track: Color = .myGroupBackground2
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous).fill(track)
                Capsule(style: .continuous).fill(progress)
                    .frame(width: value * geo.size.width)
            }
            .animation(.easeOut, value: value)
        }
    }
}
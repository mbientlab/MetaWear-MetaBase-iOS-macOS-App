// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct WarningPopover: View {

    var message: String

    @State private var isHovering = false
    var body: some View {
        SFSymbol.error.image()
            .font(.title3.bold())
            .foregroundColor(isHovering ? .yellow : .secondary)
            .popover(isPresented: $isHovering) {
                Text(message)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 250)
                    .padding()
            }
            .whenHovered { isHovering = $0 }
    }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

extension ChooseDevicesScreen {

    struct ToolbarAreaScanningIcon: View {

        var namespace: Namespace.ID
        @State private var iconIsHovered = false
        @State private var animate = false

        var body: some View {
            VStack(alignment: .center, spacing: 15) {
                MetaWearAtomAnimation(animate: animate, size: 25)
                    .onAppear { animate.toggle() }
                    .matchedGeometryEffect(id: "scanning", in: namespace)

                Text("Scanning for MetaWears")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.secondary)
                    .opacity(iconIsHovered ? 1 : 0)
            }
            .whenHovered { iconIsHovered = $0 }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeOut, value: iconIsHovered)
            .offset(y: -40)
        }
    }
}

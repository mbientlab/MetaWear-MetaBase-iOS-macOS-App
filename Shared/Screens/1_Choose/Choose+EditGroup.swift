// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ChooseDevicesScreen {

    struct EditGroupsButton: View {

        @EnvironmentObject private var vm: DiscoveryListVM
        @State private var isHovering = false

        var body: some View {
            Button { } label: {
                HStack {
                    Text("Device Groups")
                        .opacity(isHovering ? 1 : 0)
                        .adaptiveFont(.ctaMinor)

                    SFSymbol.group.image()
                        .adaptiveFont(.ctaMajor)
                }
                .whenHovered { isHovering = $0 }
                .animation(.easeOut.speed(2), value: isHovering)
            }
            .opacity(vm.listIsEmpty ? 0 : 1)
            .buttonStyle(HoverButtonStyle())
            .animation(.easeOut, value: vm.listIsEmpty)
        }
    }
}

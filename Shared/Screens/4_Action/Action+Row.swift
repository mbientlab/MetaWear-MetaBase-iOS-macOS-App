// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import Combine
import MetaWear
import MetaWearSync
import SwiftUI

extension ActionScreen {

    struct Row: View {

        @EnvironmentObject private var action: ActionVM
        @Environment(\.namespace) private var namespace
        @ObservedObject var vm: AboutDeviceVM
        var nameWidth: CGFloat
        @Environment(\.reverseOutColor) private var reverseOut

        var body: some View {
            let connectionSpacing = CGFloat(35)
            HStack(spacing: 15) {

                SharedImages.metawearTop.image()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 1, y: 1)

                Text(vm.meta.name)
                    .font(.title2.weight(isActionFocus ? .medium : .regular))
                    .padding(.trailing, connectionSpacing)
                    .reportMaxWidth(to: NameWK.self)
                    .frame(minWidth: nameWidth, alignment: .leading)

                ConnectionIcon(color: foreground)
                LargeSignalDots(color: foreground, dotSize: 9, spacing: 3)

                HStack(alignment: .center) {
                    ProgrammingStateIcon(vm: vm, invertTextColor: isActionFocus)
                        .padding(.trailing, 10)

                    ProgressSummaryLabel(vm: vm, invertTextColor: isActionFocus)
                }
                .padding(.leading, connectionSpacing)
            }
            .environment(\.signalLevel, vm.rssi)
            .environment(\.connectionState, vm.connection)
            .contextMenu { if case ActionState.error = action.actionState[vm.meta.mac]! {
                Button("Factory Reset") { vm.reset() }
            } }
            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
            .padding()
            .foregroundColor(foreground)
            .background(background)
            .animation(.easeOut, value: action.actionState[vm.meta.mac]!)
        }

       @ViewBuilder private var background: some View {
           if isActionFocus {
               RoundedRectangle(cornerRadius: 8, style: .continuous)
                   .fill(Color.myHighlight)
                   .matchedGeometryEffect(id: "focus", in: namespace!)
           }
        }

        private var isActionFocus: Bool { action.actionFocus == vm.meta.mac }

        private var foreground: Color { isActionFocus ? reverseOut : .myPrimary }
    }
}

extension ActionScreen {

    struct NameWK: MaxWidthKey {
        public static var defaultValue: CGFloat = 80
    }

}

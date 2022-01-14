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
            content
                .environment(\.signalLevel, vm.rssi)
                .environment(\.connectionState, vm.connection)
                .contextMenu {
                    if case ActionState.error = action.actionState[vm.meta.mac]! {
                        Button("Factory Reset") { vm.reset() }
                    }}
                .onAppear(perform: vm.onAppear)
                .padding()
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .foregroundColor(foreground)
                .background(background)
                .animation(.easeOut, value: action.actionState[vm.meta.mac]!)
        }

        @ViewBuilder var content: some View {
            if idiom == .iPhone {
                VStack(alignment: .leading, spacing: 20) {
                    AccessibilityHStack(vstackAlign: .center,
                                        vSpacing: spacing,
                                        hstackAlign: .center,
                                        hSpacing: spacing) {
                        deviceLabel
                        connectionState
                    }

                    Divider()

                    actionState
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                HStack(spacing: spacing) {
                    deviceLabel
                    connectionState
                    actionState
                        .padding(.leading, connectionSpacing)
                }
            }
        }

        private let spacing = CGFloat(15)
        private let connectionSpacing = CGFloat(35)
        private let deviceImageSize: CGFloat = .init(iPad: 44, 36)

        private var deviceLabel: some View {
            HStack(spacing: spacing) {
                SharedImages.metawearTop.image()
                    .resizable()
                    .scaledToFit()
                    .frame(width: deviceImageSize, height: deviceImageSize)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 1, y: 1)

                Text(vm.meta.name)
                    .adaptiveFont(.actionDeviceTitle.bumpWeight(isActionFocus))
                    .padding(.trailing, connectionSpacing)
                    .reportMaxWidth(to: NameWK.self)
                    .frame(minWidth: nameWidth, alignment: .leading)
            }
        }

        private var connectionState: some View {
            HStack(spacing: spacing) {
                ConnectionIcon(color: foreground)
                LargeSignalDots(color: foreground, dotSize: 9, spacing: 3)
            }.opacity(0.85)
        }

        private var actionState: some View {
            HStack(alignment: .center) {
                ProgrammingStateIcon(vm: vm, invertTextColor: isActionFocus)
                    .padding(.trailing, 10)

                ProgressSummaryLabel(vm: vm, invertTextColor: isActionFocus)
            }
        }

        @ViewBuilder private var background: some View {
            if isActionFocus {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.myHighlight)
                    .matchedGeometryEffect(id: "focus", in: namespace!)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.myGroupBackground2)
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

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

extension ChooseDevicesScreen {

    /// Layout and style the screen for iPhone and portrait iPad
    ///
    struct NarrowVerticallySectionedGrid: View {

        @EnvironmentObject private var vm: DiscoveryListVM
        private let cellHeight: CGFloat = 320

        private var showRemembered: Bool { !vm.groups.isEmpty || !vm.ungrouped.isEmpty }
        private var showUnknown: Bool { !vm.unknown.isEmpty }
        var body: some View {
            ScrollView(.vertical) {
                if showRemembered { remembered }
                if showRemembered && showUnknown { divider }
                if showUnknown { nearby }
            }
            .animation(.easeInOut, value: vm.groups)
            .animation(.easeInOut, value: vm.ungrouped)
            .animation(.easeInOut, value: vm.unknown)
        }

        private var remembered: some View {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: .screenInset * 2) {
                        DeviceIterator.KnownGroups()
                            .frame(height: cellHeight, alignment: .bottom)
                        DeviceIterator.KnownUngrouped()
                            .frame(height: cellHeight, alignment: .bottom)
                    }
                    .padding(.screenInset)
                }
            } header: { SectionHeader(title: "My MetaWears") }
        }

        private var nearby: some View {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: .screenInset * 2) {
                        DeviceIterator.UnknownNearby()
                            .frame(height: cellHeight, alignment: .bottom)
                    }
                    .padding(.horizontal, .screenInset)
                }
            } header: { SectionHeader(title: "Nearby") }
        }

        private var divider: some View {
            Divider()
                .foregroundColor(.myGroupBackground)
                .padding(.screenInset)
        }
    }
}

extension ChooseDevicesScreen.NarrowVerticallySectionedGrid {

    fileprivate struct SectionHeader: View {

        let title: String
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.medium))
                .padding(.leading, .screenInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.myPrimaryTinted)
        }
    }
}

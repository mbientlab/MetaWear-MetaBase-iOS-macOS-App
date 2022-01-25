// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ChooseDevicesScreen {

    /// Layout and style the screen
    ///
    struct WideOneRowGrid: View {

        @EnvironmentObject private var vm: DiscoveryListVM
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.namespace) private var namespace
        @Namespace private var fallbackNamespace

        // Layout state
        @State private var windowWidth  = CGFloat.mainWindowMinWidth
        @State private var contentWidth = CGFloat.deviceCellWidth
        private var isStaticContentWidth: Bool {
            (contentWidth + .screenInset) < windowWidth
        }

        var body: some View {
            toggleScrollLayout
                .compositingGroup()
                .animation(.linear(duration: 0.15), value: isStaticContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .background(MeasureWidth($windowWidth))
        }

        @ViewBuilder private var toggleScrollLayout: some View {
            if isStaticContentWidth {
                grid
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    grid.padding(.horizontal, .screenInset)
                }
            }
        }

        private var grid: some View {
            HStack(alignment: .center, spacing: .screenInset * 2) {
                sections
                    .frame(height: .deviceCellHeight, alignment: .bottom)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .background(MeasureWidth($contentWidth))
            .offset(y: -.verticalHoverDelta)

            .animation(.easeOut, value: vm.groups)
            .animation(.easeOut, value: vm.ungrouped)
            .animation(.easeOut, value: vm.unknown)
            .matchedGeometryEffect(id: "\(Self.self)", in: namespace ?? fallbackNamespace)
        }

#if os(iOS)
        @ViewBuilder private var sections: some View {
            DeviceIterator.KnownGroups()
                .padding(.horizontal, CGFloat(iPhone: -.screenInset, 0))

            if showDividerA { divider }

            DeviceIterator.KnownUngrouped()
                .padding(.horizontal, CGFloat(iPhone: -.screenInset, 0))

            if showDividerB { divider }
            DeviceIterator.UnknownNearby()
        }
#else
        @ViewBuilder private var sections: some View {
            DeviceIterator.KnownGroups()
            DeviceIterator.KnownUngrouped()
            if showDividerB { divider }
            DeviceIterator.UnknownNearby()
        }
#endif
    }
}

// MARK: - Dividers

extension ChooseDevicesScreen.WideOneRowGrid {

    private var divider: some View {
        Rectangle()
            .frame(width: 1)
            .foregroundColor(colorScheme == .light ? .myPrimaryTinted.opacity(0.16) : .myGroupBackground)
            .offset(y: .init(macOS: -.verticalHoverDelta - .screenInset / 2, iOS: .verticalHoverDelta))
            .padding(.trailing, .init(iPhone: 20, 0))
    }

    private var showDividerA: Bool {
        vm.groups.isEmpty == false
        && (vm.ungrouped.isEmpty == false || vm.unknown.isEmpty == false)
    }

    private var showDividerB: Bool {
        vm.ungrouped.isEmpty == false
        && vm.unknown.isEmpty == false
    }
}

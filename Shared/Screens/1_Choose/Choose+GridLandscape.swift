// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import SwiftUI

// MARK: - MacOS / iPad Wide Grid

extension ChooseDevicesScreen {

    /// Layout and style the screen
    ///
    struct WideOneRowGrid: View {

        @EnvironmentObject private var vm: DiscoveryListVM
        @Environment(\.namespace) private var namespace
        private var isBelowStaticCountLimit: Bool { vm.deviceCount <= staticCountLimit }

        var body: some View {
            if isBelowStaticCountLimit {
                grid
                    .matchedGeometryEffect(id: "\(Self.self)", in: namespace!)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            } else {
                ScrollView(.horizontal, showsIndicators: true) {
                    grid
                        .matchedGeometryEffect(id: "\(Self.self)", in: namespace!)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .background(MeasureWidth(width: $windowWidth))
            }
        }

        private var grid: some View {
            HStack(alignment: .center, spacing: cellSpacing) {
                sections
                    .frame(height: Self.macItemHeight, alignment: .bottom)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.leading, centeringPadding)
            .padding(.trailing, isBelowStaticCountLimit ? 0 : 50)
            .offset(y: -.verticalHoverDelta)
            .animation(.easeOut, value: centeringPadding)
            .animation(.easeOut, value: vm.groups)
            .animation(.easeOut, value: vm.ungrouped)
            .animation(.easeOut, value: vm.unknown)
#if os(iOS)
            .animation(.easeOut.speed(2), value: windowWidth)
#endif
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

        // MARK: - Dividers
        @Environment(\.colorScheme) private var colorScheme
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

        // MARK: - Layout Dimensions
#if os(macOS)
        @State private var windowWidth = MainScene.minWidth
        var staticCountLimit: Int {
            let conservativeFit = windowWidth / (.deviceCellWidth * 2 + .screenInset)
            return Int(max(3, conservativeFit - 1))
        }
#else
        @State private var windowWidth = UIScreen.main.bounds.width
        let staticCountLimit: Int = idiom.is_iPhone ? 1 : Int(UIScreen.main.bounds.shortestSide / (.deviceCellWidth * 1.5))
#endif
        private let cellSpacing: CGFloat = .screenInset * 2

        private static let macItemHeight: CGFloat = 320
        private let rows = [GridItem(.fixed(Self.macItemHeight), spacing: 0, alignment: .bottom)]
    }
}

extension ChooseDevicesScreen.WideOneRowGrid {

    private var centeringPadding: CGFloat {
        if idiom.is_iOS { return isBelowStaticCountLimit ? 0 : .screenInset }
        if isBelowStaticCountLimit { return 0 }
        let usedSpace = contentWidth + .screenInset * 2
        let emptySpace = windowWidth - usedSpace
        return emptySpace <= 0 ? .screenInset : (emptySpace / 2)
    }

    private var contentWidth: CGFloat  {
        let cells = CGFloat(vm.deviceCount)
        guard cells > 0 else { return .screenInset }
        let sections = CGFloat(countSections())
        let interItemSpacing = cellSpacing * (cells - 1)
        let interSectionSpacing = (cellSpacing + .screenInset) * (max(0, sections - 1))
        let cellsContentWidth = .deviceCellWidth * 1.25 * cells
        return interItemSpacing + interSectionSpacing + cellsContentWidth + .screenInset
    }

    private func countSections() -> Int {
        (vm.groups.isEmpty ? 0 : 1)
        + (vm.ungrouped.isEmpty ? 0 : 1)
        + (vm.unknown.isEmpty ? 0 : 1)
    }
}

struct MeasureWidth: View {

    @Binding var width: CGFloat

    var body: some View {
        GeometryReader { geo  in
            Color.clear.hidden()
                .onAppear { width = geo.size.width }
                .onChange(of: geo.size.width) { if width != $0 { width = $0 } }
        }
    }
}

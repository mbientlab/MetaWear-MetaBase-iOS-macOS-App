// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

// MARK: - MacOS / iPad Wide Grid

extension ChooseDevicesScreen {

    /// Layout and style the screen
    ///
    struct WideOneRowGrid: View {

        @EnvironmentObject private var vm: DiscoveryListVM

        var body: some View {
            ScrollViewReader { scroller in
                ScrollView(.horizontal, showsIndicators: true) {
                    grid
                        .padding(.leading, centeringPadding)
                        .offset(y: -.verticalHoverDelta)
                        .animation(.interactiveSpring(), value: centeringPadding)
                        .animation(.easeInOut, value: vm.groups)
                        .animation(.easeInOut, value: vm.ungrouped)
                        .animation(.easeInOut, value: vm.unknown)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .background(measureWidth)

        }

        private var grid: some View {
            LazyHGrid(rows: rows, alignment: .center, spacing: cellSpacing) {
                sections
                    .frame(height: Self.macItemHeight, alignment: .bottom)
            }
        }

        @ViewBuilder private var sections: some View {
            DeviceIterator.KnownGroups()
#if os(iOS)
            if showDividerA { divider }
#endif
            DeviceIterator.KnownUngrouped()
            if showDividerB { divider }
            DeviceIterator.UnknownNearby()
        }

        // MARK: - Dividers

        private var divider: some View {
            Rectangle()
                .frame(width: 1)
                .foregroundColor(.myGroupBackground)
                .offset(y: -.verticalHoverDelta - .screenInset / 2)
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
        @State private var windowWidth = MainWindow.minWidth
#else
        @State private var windowWidth = UIScreen.main.bounds.width
#endif
        private var cellSpacing: CGFloat = .screenInset * 2
        private static let macItemHeight: CGFloat = 320
        private let rows = [GridItem(.fixed(Self.macItemHeight), spacing: 0, alignment: .bottom)]

        private var measureWidth: some View {
            GeometryReader { geo  in
                Color.clear
                    .onAppear { windowWidth = geo.size.width }
                    .onChange(of: geo.size.width) { windowWidth = $0 }
            }
        }
    }
}

extension ChooseDevicesScreen.WideOneRowGrid {

    private var centeringPadding: CGFloat {
        let usedSpace = contentWidth + .screenInset
        let emptySpace = windowWidth - usedSpace
        return emptySpace <= 0
        ? .screenInset
        : (emptySpace / 2)
    }

    private var contentWidth: CGFloat  {
        let cells = CGFloat(vm.deviceCount)
        let sections = CGFloat(countSections())
        let interItemSpacing = cellSpacing * (cells - 1)
        let interSectionSpacing = (cellSpacing + 1) * (max(0, sections - 1))
        let cellsContentWidth = .deviceCellWidth * cells
        return interItemSpacing + interSectionSpacing + cellsContentWidth
    }

    private func countSections() -> Int {
        (vm.groups.isEmpty ? 0 : 1)
        + (vm.ungrouped.isEmpty ? 0 : 1)
        + (vm.unknown.isEmpty ? 0 : 1)
    }
}


// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public protocol ActionHeaderVM {
    var actionType: ActionType { get }
    var representativeConfig: ModulesConfiguration { get }
    func backToHistory()
}

struct ActionHeader: View {

    let vm: ActionHeaderVM

    @Environment(\.presentationMode) private var nav
    @EnvironmentObject private var routing: Routing

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            HeaderBackButton(overrideBackAction: vm.backToHistory)

            title
                .layoutPriority(2)

            if vm.actionType == .log || vm.actionType == .stream {
                ConfigTileComposer(vm: vm)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, .screenInset)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, .screenInset)
    }

    private var title: some View {
        Text(vm.actionType.title)
            .font(.largeTitle)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Tiles

extension ActionHeader {

    struct ConfigTileComposer: View {

        let vm: ActionHeaderVM
        private static let gridItem = GridItem(.fixed(25), spacing: 5, alignment: .center)
        private static var columns: [GridItem] = Array(repeating: gridItem, count: 4)

        static let imageSize = CGFloat(18)
        static let tileSize = CGFloat(30)
        static private let gridSpacing = CGFloat(10)
        private let item = GridItem(.adaptive(minimum: Self.tileSize, maximum: Self.tileSize),
                                    spacing: Self.gridSpacing,
                                    alignment: .center)

        var body: some View {
            let config = vm.representativeConfig
            return LazyHGrid(rows: [item], alignment: .center, spacing: Self.gridSpacing) {

                if config.accelerometer != nil {
                    ConfigTile(symbol: .accelerometer)
                }
                if config.altitude != nil || config.pressure != nil {
                    ConfigTile(symbol: .barometer)
                }
                if config.ambientLight != nil {
                    ConfigTile(symbol: .ambientLight)
                }
                if config.gyroscope != nil {
                    ConfigTile(symbol: .gyroscope)
                }
                if config.humidity != nil {
                    ConfigTile(symbol: .hygrometer)
                }
                if config.magnetometer != nil {
                    ConfigTile(symbol: .magnetometer)
                }
                if config.thermometer != nil {
                    ConfigTile(symbol: .temperature)
                }
                if config.fusionEuler != nil || config.fusionGravity  != nil || config.fusionLinear != nil || config.fusionQuaternion != nil {
                    ConfigTile(symbol: .accelerometer)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    struct ConfigTile: View {

        let symbol: SFSymbol

        @State private var isHovered = false
        var body: some View {
            symbol.image()
                .resizable()
                .scaledToFit()
                .frame(width: ConfigTileComposer.imageSize, height: ConfigTileComposer.imageSize, alignment: .center)
                .frame(width: ConfigTileComposer.tileSize, height: ConfigTileComposer.tileSize, alignment: .center)
                .help(Text(symbol.accessibilityDescription))
                .foregroundColor(isHovered ? .myPrimary : .mySecondary)
                .scaleEffect(isHovered ? 1.02 : 1)
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(lineWidth: 2).foregroundColor(.mySecondary.opacity(0.1)))
                .whenHovered { isHovered = $0 }
                .animation(.easeOut, value: isHovered)
        }
    }
}

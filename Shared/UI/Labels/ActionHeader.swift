// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

public protocol ActionHeaderVM {
    var title: String { get }
    var representativeConfig: SensorConfigContainer { get }
    var showBackButton: Bool { get }
    func didTapBackButton() -> Bool
}

struct ActionHeader: View {

    let vm: ActionHeaderVM

    @Environment(\.presentationMode) private var nav
    @EnvironmentObject private var routing: Routing

    var body: some View {
        HStack {
            backButton
            title
            configTiles
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, .screenInset)
        .padding(.top)
    }

    private var configTiles: some View {
        let config = vm.representativeConfig
        return HStack(spacing: 5) {
            if config.accelerometer != nil {
                ConfigTile(symbol: .accelerometer)
            }
            if config.altitude != nil || config.pressure != nil {
                ConfigTile(symbol: .barometer)
            }
            if config.color != nil {
                ConfigTile(symbol: .color)
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
            if config.proximity != nil {
                ConfigTile(symbol: .proximity)
            }
            if config.thermometer != nil {
                ConfigTile(symbol: .temperature)
            }
            if config.fusionEuler != nil || config.fusionGravity  != nil || config.fusionLinear != nil || config.fusionQuaternion != nil {
                ConfigTile(symbol: .accelerometer)
            }
        }
    }

    private var title: some View {
        Text(vm.title)
            .font(.largeTitle)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var backButton: some View {
        if vm.showBackButton { HeaderBackButton() } else { HeaderBackButton().hidden().disabled(true).allowsHitTesting(false) }
    }
}

extension ActionHeader {

    struct ConfigTile: View {

        let symbol: SFSymbol

        var body: some View {
            symbol.image()
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundColor(.secondary)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(lineWidth: 2).foregroundColor(.secondary))
        }
    }
}

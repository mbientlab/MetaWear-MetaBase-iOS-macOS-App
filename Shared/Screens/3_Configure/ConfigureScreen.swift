// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear

struct ConfigureScreen: View {

    @StateObject private var vm: SensorConfigurationVM

    init(item: Routing.Item, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeSensorConfigurationVM(item: item))
    }

    init(routing: Routing, factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeSensorConfigurationVM(item: routing.destination.item!))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)

            ScrollView {
                Grid()
            }

            CTAs()
                .padding(.bottom, .screenInset)
                .padding(.horizontal, .screenInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
    }

}


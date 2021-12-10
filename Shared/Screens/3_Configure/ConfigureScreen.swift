// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear

struct ConfigureScreen: View {

    @StateObject private var vm: SensorConfigurationVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeSensorConfigurationVM())
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


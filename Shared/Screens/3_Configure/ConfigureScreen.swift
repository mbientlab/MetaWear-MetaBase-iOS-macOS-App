// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI
import MetaWear

struct ConfigureScreen: View {

    @StateObject private var vm: ConfigureVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeConfigureVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)
            Subhead(label: selection, trailing: { presetSessions })
                .padding(.horizontal, .screenInset)

            ScrollView {
                Grid()
                    .padding(.leading, .screenInset)
                    .padding(.top, 15)
            }

            CTAs()
                .padding(.bottom, .screenInset)
                .padding(.horizontal, .screenInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar { BluetoothErrorButton.ToolbarIcon() }
        .environmentObject(vm)
    }

    @State private var hasPresets = false
    @State private var selection = "New Session"
    private var presetSessions: some View {
        Menu("Presets") {
            Button("Save current as...") { hasPresets.toggle(); selection = "Mockup Example" }
            .disabled(vm.canStart == false)
            Divider()
            if hasPresets {
                Picker("Presets", selection: $selection) {
                    Text("Mockup Example").tag("Mockup Example")
                    Text("Example 2").tag("Example 2")
                }
                .pickerStyle(.inline)
            } else { Text("No compatible saved presets") }
        }
        .fixedSize()
#if os(macOS)
        .controlSize(.large)
#endif

    }
}

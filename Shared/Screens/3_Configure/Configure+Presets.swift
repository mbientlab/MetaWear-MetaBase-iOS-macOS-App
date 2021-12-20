// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import Foundation

extension ConfigureScreen {

    struct PresetsMenu: View {

        @EnvironmentObject var vm: ConfigureVM

        var body: some View {
            menu
                .fixedSize()
#if os(macOS)
                .controlSize(.large)
#endif
        }

        private var menu: some View {
            Menu("Presets") {

                if let current = vm.selectedPreset {
                    Button("Rename...") { vm.rename(preset: current) }
                } else {
                    Button("Save as new preset...") { vm.saveCurrentConfiguration() }
                    .disabled(vm.canStart == false)
                }

                Divider()

                if vm.presets.isEmpty == false {
                    Picker("Saved", selection: selection) {
                        ForEach(vm.presets) { preset in
                            Text(preset.name).tag(preset)
                        }
                    }
                    .pickerStyle(.inline)
                } else { Text("No compatible saved presets") }
            }
        }

        private var selection: Binding<PresetSensorConfiguration> {
            Binding(
                get: { vm.selectedPreset ?? .init(name: "", config: .init()) },
                set: { next in vm.select(preset: next) }
            )
        }
    }
}

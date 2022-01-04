// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import Foundation

extension ConfigureScreen {

    struct PresetsMenu: View {

        @EnvironmentObject private var vm: ConfigureVM
        @State private var isHovered = false

        var body: some View {
            menu
                .fixedSize()
#if os(macOS)
                .controlSize(.large)
#endif
        }

        private var menu: some View {
            Menu {

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
            } label: {
                Text("Presets")
                    .foregroundColor(isHovered ? .myHighlight : .myPrimary)
                    .font(.title3.weight(.medium))
            }
#if os(macOS)
            .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: true))
#endif
            .whenHovered { isHovered = $0 }
        }

        private var selection: Binding<PresetSensorConfiguration> {
            Binding(
                get: { vm.selectedPreset ?? .init(name: "", config: .init()) },
                set: { next in vm.select(preset: next) }
            )
        }
    }
}

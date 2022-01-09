// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension ChooseDevicesScreen {

    struct ScanningIndicator: View {

        @EnvironmentObject private var vm: DiscoveryListVM
        @EnvironmentObject private var bluetooth: BluetoothStateVM
        @Environment(\.namespace) private var namespace
        @State private var iconIsHovered = false
        @State private var animate = false

        var body: some View {
            if bluetooth.showError {
                // With only one button on the macOS toolbar, now using a shared toolbar
                #if os(iOS)
                 BluetoothErrorButton()
                #endif

                // #if os(macOS)
                // .controlSize(.large)
                // #endif
            } else { scanningToggle }
        }

        private var scanningToggle: some View {
            Button { vm.toggleScanning() } label: {
                // Resets animation state
                if bluetooth.isScanning { animation } else { animation }
            }
            .buttonStyle(.plain)
            .animation(.easeOut, value: vm.isScanning)
        }

        private var animation: some View {
            VStack(alignment: .center, spacing: 15) {
                AtomAnimation(animate: animate, size: 25, color: .myPrimary)
                    .onAppear { if vm.isScanning { animate.toggle() } }
                    .matchedGeometryEffect(id: "scanning", in: namespace!)
                    .contentShape(Rectangle())

                hoverLabel
            }
            .whenHovered { iconIsHovered = $0 }
            .frame(maxWidth: .infinity, alignment: .center)
            .animation(.easeOut, value: iconIsHovered)
            .offset(y: idiom == .iPad ? 40 : -40)
        }

        private var hoverLabel: some View {
            Text(vm.isScanning ? "Discovering nearby MetaWears" : "Tap to restart Bluetooth discovery")
                .adaptiveFont(.scanningPrompt)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(idiom == .iPhone ? .myPrimaryTinted : .mySecondary)
                .opacity(iconIsHovered || idiom.is_iOS ? 1 : 0)
                .opacity(idiom == .iPhone ? 0.65 : 1)
        }
    }
}

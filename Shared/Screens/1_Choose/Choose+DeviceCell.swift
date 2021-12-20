// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import CoreBluetooth
import MetaWearSync
import SwiftUI

extension ChooseDevicesScreen {

    /// Multi-purpose list cell for MetaWear device groups, solo devices, and unknown devices
    ///
    struct DeviceCell<VM: ItemVM>: View {

        let state: ItemState
        let vm: VM

        @State private var isHovered = false
        let spacing = CGFloat(20)

        var body: some View {
            VStack(spacing: spacing) {
                MobileComponents(
                    name: state.name,
                    models: state.models,
                    isGroup: state.isGroup,
                    ledEmulator: state.ledVM,
                    isUnrecognized: state.isUnrecognized
                )
                    .onTapGesture { vm.connect() }

                StatusIndicator(
                    isWorking: state.isWorking,
                    showCloudSync: state.showCloudSync
                )

                LargeSignalDots(color: .myPrimary)
                    .opacity(isHovered ? 1 : 0.75)
                    .padding(.top, 20)

                IdentifyTextButton(
                    identifyHelpText: state.identifyTip,
                    requestIdentify: vm.identify,
                    allowIdentification: state.isLocallyKnown
                )
                    .opacity(isHovered ? 1 : 0)
            }
            .frame(width: .deviceCellWidth)
            .whenHovered { isHovered = $0 }

            .environment(\.isHovered, isHovered)
            .environment(\.isDimmed, state.isLocallyKnown == false)
            .environment(\.connectionState, state.connection)
            .environment(\.signalLevel, state.rssi)

            .animation(.spring(), value: isHovered)
            .animation(.easeOut, value: state.connection)
            .animation(.spring(), value: state.isIdentifying)

            .onAppear(perform: vm.onAppear)
            .onDisappear(perform: vm.onDisappear)
        }
    }
}

extension ChooseDevicesScreen.DeviceCell {

    /// Components of the cell that move up and down in response to user hover/select/drop behaviors
    ///
    struct MobileComponents: View {

        @Environment(\.isDropTarget) private var isDropping
        @Environment(\.isHovered) private var isHovering
        @Environment(\.connectionState) private var connection
        var name: String
        var models: [(mac: String, model: MetaWear.Model)]
        var isGroup: Bool
        let ledEmulator: MWLED.Flash.Pattern.Emulator
        let isUnrecognized: Bool

        var body: some View {
            DropOutcomeIndicator()
                .offset(y: connection == .connected ? .verticalHoverDelta / 2 : 0)
                .zIndex(2)

            ConnectionIcon()
                .opacity(connection == .connected ? 1 : 0)
                .offset(y: isHovering ? -.verticalHoverDelta : 0)
                .offset(y: isDropping ? -.verticalHoverDelta * 2 : 0)

            Text(name)
                .font(.system(.title, design: .rounded))
                .offset(y: isHovering ? -.verticalHoverDelta : 0)
                .offset(y: isDropping ? -.verticalHoverDelta * 2 : 0)
                .foregroundColor(.myPrimary)

            MetaWearImages(isGroup: isGroup, models: models, ledEmulator: ledEmulator)
                .overlay(unknownPrompt)
        }

        @ViewBuilder private var unknownPrompt: some View {
            if isUnrecognized {
                OutcomeIndicator(outcome: "Add to List", show: isHovering)
                    .compositingGroup()
                    .shadow(radius: 10)
            }
        }
    }

    /// Without changing vertical spacing, alternately show the optional
    /// cloud sync icon or express some "is working" state
    ///
    struct StatusIndicator: View {

        var isWorking: Bool
        var showCloudSync: Bool

        var body: some View {
            icloudSynced
                .opacity(isWorking ? 0 : 1)
                .overlay(connectionIndicator)
                .animation(.easeOut, value: isWorking)
                .animation(.easeOut, value: showCloudSync)
        }

        @ViewBuilder private var connectionIndicator: some View {
            if isWorking { ProgressSpinner() }
        }

        private var icloudSynced: some View {
            SFSymbol.icloud.image()
                .font(.headline)
                .help(Text("Synced via iCloud"))
                .accessibilityLabel(Text(SFSymbol.icloud.accessibilityDescription))
                .opacity(showCloudSync ? 0.75 : 0)
                .accessibilityHidden(showCloudSync == false)
        }
    }

    /// Trigger LED and haptic-based identification
    ///
    struct IdentifyTextButton: View {

        /// MAC string(s)
        var identifyHelpText: String
        let requestIdentify: () -> Void
        var allowIdentification: Bool

        var body: some View {
            Button { requestIdentify() } label: { label }
            .foregroundColor(.myPrimary)
            .buttonStyle(.borderless)
            .allowsHitTesting(allowIdentification)
            .disabled(allowIdentification == false)
            .opacity(allowIdentification ? 1 : 0)
        }

        private var label: some View {
            Text("Identify")
                .font(.headline)
                .lineLimit(1)
                .fixedSize()
                .help(Text(identifyHelpText))
        }
    }

    struct MetaWearImages: View {

        var isGroup: Bool
        var models: [(mac: String, model: MetaWear.Model)]
        let ledEmulator: MWLED.Flash.Pattern.Emulator

        @Environment(\.isDropTarget) private var isDropping
        @Environment(\.isHovered) private var isHovering
        @Environment(\.dragProvider) private var dragProvider

        private var imageWidth: CGFloat { 140 }

        private var imageHeight: CGFloat { isHovering ? 160 : 135 }

        var overlap: CGFloat { models.endIndex <= 2 ? 0.2 : 0.4 }

        private var groupCenteringXOffset: CGFloat {
            let oneLess = max(0, min(3, models.endIndex - 1))
            return CGFloat(oneLess) * imageWidth * overlap / 2
        }

        var body: some View {
            HStack(spacing: 0) {
                if isGroup { groupImages } else {
                    MetaWearWithLED(
                        width: imageWidth,
                        height: imageHeight,
                        ledEmulator: ledEmulator
                    ).environment(\.metaWearModel, models.first?.model ?? .unknown)
                }
            }
            .frame(width: imageWidth, height: imageHeight, alignment: .center)
            .onDrag(dragProvider)

            .background(backgrounds)
            .animation(.spring(), value: isDropping)
            .animation(.spring(), value: isHovering)
        }

        private var backgrounds: some View {
            HStack {
                if isGroup { groupBackgrounds } else {
                    ZStack {
                        MetaWearOutline(width: imageWidth, height: imageHeight)
                        MetaWearShadow(width: imageWidth, height: imageHeight)
                    }
                    .environment(\.metaWearModel, models.first?.model ?? .unknown)
                }
            }
            .frame(width: imageWidth, height: imageHeight, alignment: .center)
        }

        private let groupItemScale: CGFloat = 0.6

        private var groupImages: some View {
            let centering = groupCenteringXOffset
            return ForEach(models.prefix(3), id: \.mac) { (id, model) in
                let index = models.firstIndex(where: { $0.mac == id }) ?? 0

                MetaWearWithLED(
                    width: imageWidth * groupItemScale,
                    height: imageHeight * groupItemScale,
                    ledEmulator: ledEmulator
                )
                    .environment(\.metaWearModel, model)
                    .arrangeGroupedMetaWearImages(at: index, overlap: imageWidth * overlap, xCentering: centering)
            }
        }

        /// Split into two layers so the solid color appears unified, not split per device
        private var groupBackgrounds: some View {
            let centering = groupCenteringXOffset
            let width = imageWidth * groupItemScale
            let height = imageHeight * groupItemScale
            return ZStack {

                // Solid color
                HStack(spacing: 0) {
                    ForEach(models.prefix(3), id: \.mac) { (id, model) in
                        let index = models.firstIndex(where: { $0.mac == id }) ?? 0

                        MetaWearOutline(width: width, height: height)
                            .environment(\.metaWearModel, model)
                            .arrangeGroupedMetaWearImages(at: index, overlap: imageWidth * overlap, xCentering: centering)
                    }
                }

                // Shadows
                HStack(spacing: 0) {
                    ForEach(models.prefix(3), id: \.mac) { (id, model) in
                        let index = models.firstIndex(where: { $0.mac == id }) ?? 0

                        MetaWearShadow(width: width, height: height)
                            .environment(\.metaWearModel, model)
                            .opacity(0.5) // Reduce overlap of group shadows
                            .arrangeGroupedMetaWearImages(at: index, overlap: imageWidth * overlap, xCentering: centering)
                    }
                }
            }
        }
    }
}

fileprivate extension View {

    func arrangeGroupedMetaWearImages(at index: Int, overlap: CGFloat, xCentering: CGFloat) -> some View {

        var rotation: Angle {
            switch index {
                case 0: return .degrees(5)
                case 1: return .degrees(-5)
                case 2: return .degrees(2)
                default: return .degrees(0)
            }
        }

        return self
            .offset(x: CGFloat(index) * -overlap)
            .offset(x: xCentering)
            .rotationEffect(rotation)
            .zIndex(-Double(index))
            .offset(y: index == 2 ? 9 : 0)

    }

}

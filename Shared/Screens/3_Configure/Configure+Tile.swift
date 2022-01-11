// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct Tile<Frequency: Listable, Option: Listable>: View {

        @Environment(\.reverseOutColor) private var reverseOut
        @Environment(\.colorScheme) private var colorScheme

        // State
        let module: String
        let symbol: SFSymbol
        @Binding var isSelected: Bool

        // Options
        @Binding var frequency: Frequency
        let frequencies: [Frequency]

        @Binding var option: Option
        var options: [Option] = []
        var optionsHelp: String = ""

        // Button state
        @State private var isHovered = false

        var body: some View {
            VStack {
                moduleLabel.hidden()

                if isSelected {
                    if options.isEmpty { optionsMenu.hidden() } else { optionsMenu }
                    Spacer()
                    if isSelected { frequencyMenu }
                }
            }
            .padding()
            .frame(width: Grid.tileWidth, height: Grid.tileHeight, alignment: .top)
            .background(button)
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            .animation(.easeOut(duration: 0.2), value: isSelected)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }

        // MARK: - Label

        private var moduleLabel: some View {
            VStack(spacing: 12) {
                symbol.image()
                    .scaledToFit()
                    .frame(width: 40, height: 25)
                    .adaptiveFont(.configureTileTitle.adjustingSize(points: 5).withWeight(.bold))

                Text(module)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .adaptiveFont(.configureTileTitle.adjustingWeight(steps: isSelected ? 1 : 0))

            }
            .foregroundColor(textColor)
            .padding(.top, idiom == .macOS ? 10 : 20)
        }

        private var textColor: Color {
            if isSelected { return reverseOut }
            else { return isHovered ? .myHighlight : .myPrimary }
        }

        // MARK: - Options

        private var frequencyMenu: some View {
            CrossPlatformStylizedMenu(
                selected: $frequency,
                options: frequencies,
                labelFont: .configureTileMenu,
                labelColor: reverseOut
            )
                .animation(nil)
#if os(macOS)
                .fixedSize()
#endif
                .frame(maxWidth: .infinity, alignment: .center)
#if os(iOS)
                .background(preventUnwantedTouchesOn_iOS)
#endif
                .padding(.bottom, idiom == .macOS ? 0 : 7)
                .help(Text("Sampling Frequency"))
        }

        private var showOptions: Bool { isSelected }
        private var optionsMenu: some View {
            CrossPlatformStylizedMenu(
                selected: $option,
                options: options,
                labelFont: .configureTileMenu,
                labelColor: reverseOut
            )
                .animation(nil)
#if os(macOS)
                .fixedSize()
#endif
                .frame(maxWidth: .infinity, alignment: .center)
                .help(Text(optionsHelp))
                .padding(.top, idiom == .macOS ? 0 : 5)
                .background(preventUnwantedTouchesOn_iOS)
                .opacity(showOptions ? 1 : 0)
                .disabled(showOptions == false)
                .allowsHitTesting(showOptions)
        }

        private var preventUnwantedTouchesOn_iOS: some View {
            Button { } label: { Color.clear }
            .accessibilityHidden(true)
            .buttonStyle(.borderless)
        }

        // MARK: - Button

        private var button: some View {
            Button { isSelected.toggle() } label: {
                ZStack(alignment: .top) {
                    let shape = RoundedRectangle(cornerRadius: 8)
                    shape
                        .trim(from: 0, to: isSelected ? 1 : 0)
                        .foregroundColor((isSelected ? Color.myHighlight : .clear).opacity(backgroundOpacity))
#if os(iOS)
                        .brightness(colorScheme == .dark ? -0.13 : -0.05)
#endif
                        .animation(.spring(), value: isSelected)
                    shape
                        .strokeBorder(lineWidth: 2)
                        .foregroundColor(isHovered ? .myHighlight : .myPrimary.opacity(0.2))
                        .opacity(isSelected ? 0 : 1)

                    moduleLabel.padding()
                }
                .contentShape(Rectangle())
                .whenHovered { isHovered = $0 }
            }
            .buttonStyle(DepressButtonStyle())
        }

        private var backgroundOpacity: Double {
            if isHovered { return isSelected ? 1 : 0.05 }
            else { return isSelected ? 1 : 0 }
        }
    }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct Tile<Frequency: Listable, Option: Listable>: View {

        @Environment(\.reverseOutColor) private var reverseOut

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
            .animation(.easeOut(duration: 0.2), value: isSelected)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }

        // MARK: - Label

        private var moduleLabel: some View {
            VStack(spacing: 12) {
                symbol.image()
                    .scaledToFit()
                    .frame(width: 40, height: 25)
                    .font(.title.weight(.semibold))

                Text(module)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .font(.title3.weight(isSelected ? .semibold : .medium))

            }
            .foregroundColor(textColor)
            .padding(.top, 10)
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
                labelFont: .title3.weight(.semibold),
                labelColor: reverseOut
            )
                .animation(nil)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .center)
                .help(Text("Sampling Frequency"))
        }

        private var showOptions: Bool { isSelected }
        private var optionsMenu: some View {
            CrossPlatformStylizedMenu(
                selected: $option,
                options: options,
                labelFont: .title3.weight(.semibold),
                labelColor: reverseOut
            )
                .animation(nil)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .center)
                .help(Text(optionsHelp))

                .opacity(showOptions ? 1 : 0)
                .disabled(showOptions == false)
                .allowsHitTesting(showOptions)
        }

        // MARK: - Button

        private var button: some View {
            Button { isSelected.toggle() } label: {
                ZStack(alignment: .top) {
                    let shape = RoundedRectangle(cornerRadius: 8)
                    shape
                        .trim(from: 0, to: isSelected ? 1 : 0)
                        .foregroundColor((isSelected ? Color.myHighlight : .clear).opacity(backgroundOpacity))
                        .animation(.spring(), value: isSelected)
                    shape
                        .strokeBorder(lineWidth: 2)
                        .foregroundColor(isHovered || isSelected ? .myHighlight : .myPrimary.opacity(0.2))

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

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

extension ConfigureScreen {

    struct Tile<Frequency: Listable, Option: Listable>: View {

        let module: String
        let symbol: SFSymbol
        @Binding var isSelected: Bool

        @Binding var frequency: Frequency
        let frequencies: [Frequency]

        @Binding var option: Option
        var options: [Option] = []
        var optionsHelp: String = ""
        var alwaysShowOptions = false

        var body: some View {
            VStack {
                VStack(spacing: 12) {
                    symbol.image()
                        .scaledToFit()
                        .frame(width: 40, height: 25)
                        .font(.title.weight(.semibold))

                    Text(module)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                        .font(.title3.weight(.medium))
                }
                .padding(.top, 10)

                if options.isEmpty { optionsMenu.hidden() } else { optionsMenu }
                Spacer()
                if isSelected { frequencyMenu }
            }
            .padding()
            .frame(width: Grid.tileWidth, height: Grid.tileHeight)
            .background(background.onTapGesture { isSelected.toggle() })
            .animation(.easeOut(duration: 0.2), value: isSelected)
            .animation(.easeOut(duration: 0.2), value: isHovered)
        }

        @State private var isHovered = false
        private var backgroundOpacity: Double {
            if isHovered { return isSelected ? 0.2 : 0.05 }
            else { return isSelected ? 0.15 : 0 }
        }
        private var background: some View {
            ZStack {
                let shape = RoundedRectangle(cornerRadius: 8)
                shape.foregroundColor(.white.opacity(backgroundOpacity))
                shape.strokeBorder(lineWidth: 2).foregroundColor(.white.opacity(isSelected ? 0 : 0.2))
            }
            .contentShape(Rectangle())
            .whenHovered { isHovered = $0 }
        }

        private var frequencyMenu: some View {
            CrossPlatformMenu(selected: $frequency, options: frequencies)
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(Text("Sampling Frequency"))
        }

        private var showOptions: Bool { alwaysShowOptions || isSelected }
        private var optionsMenu: some View {
            CrossPlatformMenu(selected: $option, options: options, labelFont: .body.weight(.medium))
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help(Text(optionsHelp))

                .opacity(showOptions ? 1 : 0)
                .disabled(showOptions == false)
                .allowsHitTesting(showOptions)
        }
    }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

struct ConfigureScreen: View {

    @StateObject private var vm: ConfigureVM
    @Environment(\.sizeCategory) private var dynamicType

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeConfigureVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)
                .keyboardShortcut(.cancelAction)
            
            EditableSubhead(
                label: vm.sessionNameBinding,
                placeholder: "Session Name",
                trailing: { PresetsMenu().padding(.trailing, .screenInset) }
            ).padding(.horizontal, .screenInset)
                .padding(.bottom, -8)

            ScrollView(.vertical, showsIndicators: idiom != .iPhone) {
                Grid()
                    .padding(.leading, idiom == .iPhone ? 0 : .screenInset)
                    .padding(.top, 15)

                Color.clear.frame(height: ScrollFadeMask.defaultSize / 2)
            }
            .mask(ScrollFadeMask(edge: .bottom).offset(y: 1))

#if os(macOS)
            horizontalCTARow
#elseif os(iOS)
            if idiom == .iPad { horizontalCTARow } else { verticalCTARows }
#endif
        }
        .animation(.easeInOut, value: vm.selectedPreset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
    }

    private var horizontalCTARow: some View {
        HStack {
            HStack(alignment: .center, spacing: .screenInset) {
                Estimates()
            }
            .frame(maxWidth: 450, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)

            CTAs()
        }
        .padding(.bottom, .screenInset)
        .padding(.horizontal, .screenInset)
        .layoutPriority(10)
    }

    private var verticalCTARows: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dynamicType.isAccessibilityCategory {
                Estimates()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).foregroundColor(.myGroupBackground2))
                    .padding(.horizontal, -.screenInset / 2)
            }
            else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Estimates()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).foregroundColor(.myGroupBackground3))
                .padding(.horizontal, -.screenInset / 2)
            }
            CTAs().padding(.top, 8)
        }
        .padding(.top, 10)
        .padding(.bottom, .screenInset)
        .padding(.horizontal, .screenInset)
    }
}


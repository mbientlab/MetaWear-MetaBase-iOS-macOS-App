// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI

protocol Selectable: CaseIterable, IdentifiableByRawValue {
    var displayName: String { get }
    static var allCases: [Self] { get }
    func helpView() -> AnyView?
}

struct HighlightedSegmentedControl<Selection: Selectable>: View {
    @Binding var selection: Selection

    var font: Font.Config = .ctaMajor.adjustingSize(steps: idiom == .iPhone ? -2 : -1)
    var padding: CGFloat = 6
    @Namespace private var toggle

    @State private var hovers: [Selection:Bool] = [:]

    var body: some View {
        HStack(spacing: max(0, 10 - padding)) {
            ForEach(Selection.allCases) { mode in

                if let help = mode.helpView() {

                    HighlightToggleStyle.Option(
                        label: mode.displayName,
                        color: .myHighlight,
                        isOn: mode == selection,
                        set: { selection = mode },
                        font: font,
                        padding: padding
                    )
                        .whenHovered { hovers[mode] = $0 }
                        .popover(isPresented: $hovers.isPresented(mode)) {
                            ScrollView {
                                help
                            }
                                .padding()
                            #if os(macOS)
                                .frame(width: 400, height: 400, alignment: .leading)
                            #endif
                        }

                } else {

                    HighlightToggleStyle.Option(
                        label: mode.displayName,
                        color: .myHighlight,
                        isOn: mode == selection,
                        set: { selection = mode },
                        font: font,
                        padding: padding
                    )
                }
            }
        }
        .environment(\.namespace, toggle)
        .animation(.spring().speed(2), value: selection)
    }
}

extension Binding {
    func isPresented<V: Hashable>(_ value: V) -> Binding<Bool>  where Value == [V:Bool] {
        Binding<Bool> {
            self.wrappedValue[value] ?? false
        } set: { self.wrappedValue[value] = $0 }
    }
}

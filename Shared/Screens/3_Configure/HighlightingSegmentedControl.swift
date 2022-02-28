// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear
import SwiftUI

protocol Selectable: CaseIterable, IdentifiableByRawValue {
    var displayName: String { get }
    var sfSymbol: SFSymbol { get }
    static var allCases: [Self] { get }
    func helpView() -> AnyView?
}

struct HighlightedSegmentedControl<Selection: Selectable>: View {
    @Binding var selection: Selection
    
    var font: Font.Config = .ctaMajor.adjustingSize(steps: idiom == .iPhone ? -5 : -1)
    var padding: CGFloat = 6
    var hoverDelay: Double = 0.25
    var useIcons: Bool
    @Namespace private var toggle
    
    @State private var hovers: [Selection:Bool] = [:]
    @State private var preHovers: [Selection:Bool] = [:]
    
    var body: some View {
        HStack(spacing: max(0, 10 - padding)) {
            ForEach(Selection.allCases) { mode in
                
                if useIcons {
                    ImageRow(
                        mode: mode,
                        selection: $selection,
                        font: font,
                        padding: padding,
                        delayedHover: delayedHover,
                        longPress: longPress(option:),
                        hovers: $hovers
                    )
                } else {
                    TextRow(
                        mode: mode,
                        selection: $selection,
                        font: font,
                        padding: padding,
                        delayedHover: delayedHover,
                        longPress: longPress(option:),
                        hovers: $hovers
                    )
                }
            }
        }
        .environment(\.namespace, toggle)
        .animation(.spring().speed(2), value: selection)
    }
    
    private func longPress(option: Selection) {
        hovers[option] = true
    }
    
    private func delayedHover(isHovering: Bool, option: Selection) {
        switch isHovering {
        case false:
            preHovers[option] = false
            hovers[option] = false
        case true:
            preHovers[option] = true
            DispatchQueue.main.asyncAfter(deadline: .now() + hoverDelay) {
                guard preHovers[option] == true else { return }
                hovers[option] = true
            }
        }
    }
    
    struct TextRow: View {
        var mode: Selection
        @Binding var selection: Selection
        var font: Font.Config
        var padding: CGFloat
        var delayedHover: (Bool, Selection) -> Void
        var longPress: (Selection) -> Void
        
        @Binding var hovers: [Selection:Bool]
        
        var body: some View {
            if let help = mode.helpView() {
                
                HighlightToggleStyle.Option(
                    label: mode.displayName,
                    color: .myHighlight,
                    isOn: mode == selection,
                    set: { selection = mode },
                    font: font,
                    padding: padding
                )
                    .popover(isPresented: $hovers.isPresented(mode)) { PopoverView(popover: help) }
#if os(macOS)
                    .onHover { delayedHover($0, mode) }
#else
                    .onLongPressGesture { longPress(mode) }
#endif
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
    
    struct ImageRow: View {
        var mode: Selection
        @Binding var selection: Selection
        var font: Font.Config
        var padding: CGFloat
        var delayedHover: (Bool, Selection) -> Void
        var longPress: (Selection) -> Void
        
        @Binding var hovers: [Selection:Bool]
        
        var body: some View {
            if let help = mode.helpView(), selection == mode {
                
                HighlightToggleStyle.Option(
                    label: mode.displayName,
                    color: .myHighlight,
                    isOn: mode == selection,
                    set: { selection = mode },
                    font: font,
                    padding: padding
                )
                    .popover(isPresented: $hovers.isPresented(mode)) { PopoverView(popover: help) }
#if os(macOS)
                    .onHover { delayedHover($0, mode) }
#else
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { if $0 { longPress(mode) } },
                        including: GestureMask.all
                    )
#endif
                
            } else if selection == mode {
                
                HighlightToggleStyle.Option(
                    label: mode.displayName,
                    color: .myHighlight,
                    isOn: mode == selection,
                    set: { selection = mode },
                    font: font,
                    padding: padding
                )
                
            } else if let help = mode.helpView() {
                
                HighlightToggleStyle.Option(
                    symbol: mode.sfSymbol,
                    color: .myHighlight,
                    isOn: mode == selection,
                    set: { selection = mode },
                    font: font,
                    padding: padding
                )
                    .popover(isPresented: $hovers.isPresented(mode)) { PopoverView(popover: help) }
#if os(macOS)
                    .onHover { delayedHover($0, mode) }
#else
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { if $0 { longPress(mode) } },
                        including: GestureMask.all
                    )
#endif
            } else {
                
                HighlightToggleStyle.Option(
                    symbol: mode.sfSymbol,
                    color: .myHighlight,
                    isOn: mode == selection,
                    set: { selection = mode },
                    font: font,
                    padding: padding
                )
            }
        }
    }
}

struct PopoverView<Popover: View>: View {
    var popover: Popover
    var body: some View {
        ScrollView { popover }
        .padding(.top)
        .padding(.horizontal)
#if os(macOS)
        .padding(.bottom)
        .frame(width: 350, height: 500, alignment: .leading)
#elseif os(iOS)
        .ignoresSafeArea(.container, edges: .bottom)
#endif
    }
}

extension Binding {
    func isPresented<V: Hashable>(_ value: V) -> Binding<Bool>  where Value == [V:Bool] {
        Binding<Bool> {
            self.wrappedValue[value] ?? false
        } set: { self.wrappedValue[value] = $0 }
    }
}

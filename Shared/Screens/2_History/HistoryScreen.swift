// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import Combine
import mbientSwiftUI
import MetaWear
import MetaWearSync

struct HistoryScreen: View {

    @EnvironmentObject private var factory: UIFactory
    @StateObject private var vm: HistoryScreenVM

    init(_ factory: UIFactory) {
        _vm = .init(wrappedValue: factory.makeHistoryScreenVM())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header(vm: vm)
                .keyboardShortcut(.cancelAction)
#if os(macOS)
            wideLayout
#else
            if idiom == .iPhone { narrowLayout } else { wideLayout }
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environmentObject(vm)
        .onAppear(perform: vm.onAppear)
    }

    @State private var spinRefresh: Double = 0
    private func refreshAnimationIntercept() {
        spinRefresh += 360
        vm.refresh()
    }

    /// macOS + iPad
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: .screenInset) {

            VStack(alignment: .leading) {
                ScreenSubsection(label: "About", trailing: {
                    RefreshButton(help: "Refresh All", didTap: refreshAnimationIntercept)
                        .buttonStyle(HoverButtonStyle())
                        .opacity(vm.showSessionStartAlert ? 0 : 1)
                        .rotationEffect(.degrees(spinRefresh))
                        .animation(.spring().speed(0.4), value: spinRefresh)
                })

                DevicesList()
            }
            .frame(minWidth: idiom.is_Mac ? 230 : 260)

            VStack(alignment: .leading) {
                SessionListStaticSubhead()
                SessionsList(factory, scrollingTopContent: { EmptyView() })

                CTAs(layoutVertically: idiom == .iPhone)
                    .padding(.top, .screenInset / 2)
                    .padding(.bottom, .screenInset)
                    .layoutPriority(2)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, .screenInset)
        .padding(.top, 5)
    }

#if os(iOS)
    @State private var showiOSAboutSheet = false

    private var narrowLayout: some View {
        VStack(alignment: .leading, spacing: 0) {

            if #available(iOS 15, *) {
                SessionsList(factory, scrollingTopContent: {
                    iOSAboutDevicesButton
                        .padding(.top, .screenInset * 1.5)
                        .padding(HistoryScreen.listEdgeInsets.inverted())
                        .listRowSeparator(.hidden)

                    SessionListStaticSubhead()
                        .padding(HistoryScreen.listEdgeInsets.horizontalInverted())
                        .listRowSeparator(.hidden)
                })
            } else {
                SessionsList(factory, scrollingTopContent: {
                    iOSAboutDevicesButton
                        .padding(.top, .screenInset * 1.5)
                        .padding(HistoryScreen.listEdgeInsets.inverted())

                    SessionListStaticSubhead()
                        .padding(HistoryScreen.listEdgeInsets.horizontalInverted())
                })
            }

            CTAs(layoutVertically: idiom == .iPhone)
                .padding(.top, .screenInset / 2)
                .padding(.bottom, .screenInset)
                .padding(.horizontal, .screenInset)
                .layoutPriority(2)
        }
        .padding(.top, -.screenInset * 1.5)
        .padding(.top, 8)
        .onAppear { vm.items.forEach { $0.onAppear() } }
    }

    @Environment(\.colorScheme) private var colorScheme
    private var sheetBG: Color { colorScheme == .light ? .lightModeFaintBG : .defaultSystemBackground }

    private var iOSAboutDevicesButton: some View {
        Button { showiOSAboutSheet.toggle() } label: {
            ScreenSubsection(label: vm.items.endIndex > 1 ? "Devices" : "Device", trailing: {
                SFSymbol.nextChevron.image().foregroundColor(.myTertiary)
            })
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, .screenInset / 2)
        .sheet(isPresented: $showiOSAboutSheet) {
            DevicesList(initiallyShowDetails: true)
                .modifier(CloseSheet())
                .background(sheetBG.edgesIgnoringSafeArea(.all))
                .edgesIgnoringSafeArea(.bottom)
        }
    }
#endif
}

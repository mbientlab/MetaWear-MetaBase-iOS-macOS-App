// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

public protocol HeaderVM {
    var title: String { get }
    var deviceCount: Int { get }
    var showBackButton: Bool { get }
}

struct Header: View {

    let vm: HeaderVM
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 15) {

            if vm.showBackButton { HeaderBackButton() }
            else { HeaderBackButton().hidden().disabled(true).allowsHitTesting(false) }

            Text(vm.title)
                .adaptiveFont(.screenHeader)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(colorScheme == .light ? .myPrimaryTinted : .myPrimary)

            Spacer()

            Icons(vm: vm)
                .padding(.trailing, .screenInset)
                .offset(y: -.headerMinHeight / 5)
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, minHeight: .headerMinHeight, alignment: .topLeading)
        .padding(.top, .headerTopPadding)
        .backgroundToEdges(.myBackground)
        .padding(.bottom, .screenInset)
    }
}

struct HeaderBackButton: View {

    @EnvironmentObject private var routing: Routing
    @Environment(\.reverseOutColor) private var reverseOut
    @Environment(\.colorScheme) private var colorScheme

    @State private var isHovered = false

    var overrideBackAction: (() -> Void)? = nil

    var body: some View {
        Button{
            if let back = overrideBackAction {
                back()
                return
            }
            routing.goBack()

        } label: {
            SFSymbol.back.image()
                .adaptiveFont(.screenHeaderBackIcon)
                .foregroundColor(isHovered ? .myHighlight : restingBackArrowColor)
                .offset(x: isHovered ? -5 : 0)
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .frame(minWidth: 65, maxWidth: nil, alignment: .center)
        }
        .buttonStyle(UnderlinedButtonStyle(color: .myHighlight,
                                           isHovered: isHovered,
                                           incognitoUnderline: true))
        .brightness(colorScheme == .light && isHovered ? -0.08 : 0)
        .whenHovered { isHovered = $0 }
        .animation(.spring(), value: isHovered)
        .padding(.leading, 10)

#if os(macOS)
        .controlSize(.large)
#endif
    }

    var restingBackArrowColor: Color {
        colorScheme == .light ? .mySecondary : .myTertiary
    }
}

extension Header {

    struct Icons: View {

        let vm: HeaderVM
        @State private var iconsDidAppear = false
        private static let deviceIconMaxSize = idiom == .iPad ? CGFloat(90) : CGFloat(70)

        var body: some View {
            if vm.deviceCount > 0 {
                deviceImage
                    .rotationEffect(.degrees(-3))
                    .frame(width: Self.deviceIconMaxSize)
                    .background(secondDevice.offset(x: secondDeviceXOffset), alignment: .topTrailing)
                    .background(thirdDevice.offset(x: thirdDeviceXOffset), alignment: .topTrailing)
                #if os(iOS)
                    .compositingGroup()
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 3, y: 3)
                #endif
                    .animation(.easeOut, value: iconsDidAppear)
                    .onAppear { DispatchQueue.main.after(0.35) { iconsDidAppear.toggle() } }
                    .padding(.trailing, 12 * CGFloat(vm.deviceCount))
            }
        }

        @ViewBuilder private var secondDevice: some View {
            if vm.deviceCount > 1 {
                deviceImage.frame(width: Self.deviceIconMaxSize * 0.95)
                    .rotationEffect(iconsDidAppear ? .degrees(-12) : .degrees(0), anchor: .top)
            }
        }

        @ViewBuilder private var thirdDevice: some View {
            if vm.deviceCount > 2 {
                deviceImage.frame(width: Self.deviceIconMaxSize * 0.85)
                    .rotationEffect(iconsDidAppear ? .degrees(-18) : .degrees(0), anchor: .top)
            }
        }

        private var deviceImage: some View {
            SharedImages.metawearTop.image()
                .resizable()
                .scaledToFit()
        }

        private var secondDeviceXOffset: CGFloat {
            iconsDidAppear ? Self.deviceIconMaxSize / 3.3 : 0
        }

        private var thirdDeviceXOffset: CGFloat {
            iconsDidAppear ? Self.deviceIconMaxSize / 2 : 0
        }
    }
}

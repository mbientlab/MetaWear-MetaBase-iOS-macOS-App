// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import mbientSwiftUI

public protocol HeaderVM {
    var title: String { get }
    var deviceCount: Int { get }
    var showBackButton: Bool { get }
}

struct Header: View {

    let vm: HeaderVM

    var body: some View {
        HStack {
            backButton

            HStack {
                icons
                title
            }
            .offset(x: titleIconXOffset)
            .frame(maxWidth: .infinity, alignment: .center)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, .screenInset)
    }

    private var titleIconXOffset: CGFloat {
        Self.deviceIconMaxSize * -CGFloat(vm.deviceCount) - (Self.deviceIconMaxSize / 2)
    }
    @State private var iconsDidAppear = false
    private static let deviceIconMaxSize = CGFloat(30)
    @ViewBuilder private var icons: some View {
        if vm.deviceCount > 0 {
            deviceImage
                .rotationEffect(.degrees(-3))
                .frame(width: Self.deviceIconMaxSize)
                .background(secondDevice.offset(x: iconsDidAppear ? Self.deviceIconMaxSize / 3.3 : 0), alignment: .topTrailing)
                .background(thirdDevice.offset(x: iconsDidAppear ? Self.deviceIconMaxSize / 2 : 0), alignment: .topTrailing)
                .animation(.easeOut, value: iconsDidAppear)
                .onAppear { DispatchQueue.main.after(0.5) { iconsDidAppear.toggle() } }
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
        Images.metawearTop.image()
            .resizable()
            .scaledToFit()
    }

    private var title: some View {
        Text(vm.title)
            .font(.largeTitle)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var backButton: some View {
        if vm.showBackButton { HeaderBackButton() } else { HeaderBackButton().hidden().disabled(true).allowsHitTesting(false) }
    }
}

struct HeaderBackButton: View {

    @Environment(\.presentationMode) private var nav
    @EnvironmentObject private var routing: Routing

    @State private var backIsHovered = false
    var body: some View {
        Button{
            #if os(iOS)
            nav.wrappedValue.dismiss()
            #else
            routing.goBack()
            #endif

        } label: {
            ZStack {
                CorneredRect(rounding: [.topRight, .bottomRight], by: 10)
                    .fill(.white.opacity(backIsHovered ? 0.2 : 0))

                SFSymbol.back.image()
                    .font(.title2)
                    .foregroundColor(.white.opacity(backIsHovered ? 1 : 0.4))
                    .padding(.vertical, 9)
                    .padding(.trailing, 12)
                    .padding(.leading, .screenInset / 2)
            }
        }
        .buttonStyle(.borderless)
        .fixedSize()
        .whenHovered { backIsHovered = $0 }
        .animation(.easeOut, value: backIsHovered)
    }
}

// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI
import MetaWear

extension ChooseDevicesScreen {

    struct NoDevicesFound: View {
        static var transitionInterval = Double(1)
        let shouldShowList: Binding<Bool>
        var body: some View {
            GeometryReader { Content(geo: $0, shouldDisappear: shouldShowList) }
        }
    }
}

private extension ChooseDevicesScreen.NoDevicesFound {

    struct Content: View {

        let geo: GeometryProxy
        let shouldDisappear: Binding<Bool>
        @Environment(\.namespace) private var namespace

        // Coordinate an animated disappearance
        @EnvironmentObject private var vm: DiscoveryListVM
        private var willDisappear: Bool { vm.listIsEmpty == false && hasUsed >= CurrentMetaBaseVersion }

        // Coordinate the transition animations
        @AppStorage(wrappedValue: 0.0, UserDefaults.MetaWear.Keys.hasUsedMetaBaseVersion) private var hasUsed
        @State private var didAppear = false
        @State private var animate = false

        var body: some View {
            VStack(alignment: .center) {
                if didAppear { atomAnimation }
                if didAppear { instruction }
                if didAppear { heroImage }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottom
            )
            .background(hueGradient)
            .animation(.easeInOut(duration: transitionInterval), value: didAppear)
            .onAppear(perform: startAnimations)
            .onChange(of: willDisappear, perform: startDisappearance)
        }

        private func startAnimations() {
            didAppear.toggle()
            hasUsed = CurrentMetaBaseVersion
            DispatchQueue.main.after(transitionInterval) {
                animate.toggle()
            }
        }

        private func startDisappearance(_ willDisappear: Bool) {
            didAppear.toggle()
            DispatchQueue.main.after(transitionInterval) {
                shouldDisappear.wrappedValue.toggle()
            }
        }

        // MARK: - Progress Animation

        private var atomAnimation: some View {
            let removal = AnyTransition.move(edge: .top)
            let insertion = AnyTransition
                .scale
                .animation(.spring(
                    response: 0.2,
                    dampingFraction: 0.5,
                    blendDuration: 1
                ).delay(transitionInterval + 0.15))

            return MetaWearAtomAnimation(
                animate: animate,
                size: min(180, max(90, geo.size.width * 0.15))
            )
                .matchedGeometryEffect(id: "scanning", in: namespace!)
                .padding(.bottom, 75)
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - Instruction

        private var instruction: some View {
            var text: some View {
                Text("Finding nearby MetaWear")
                    .font(.largeTitle)
            }

            let removal = AnyTransition.opacity
            let insertion = removal.animation(.default.delay(transitionInterval))

            return SpotlightShimmerText(
                foreground: text,
                animate: animate,
                travel: geo.size.width
            )
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - Hero

        private var heroImage: some View {
            let removal = AnyTransition
                .move(edge: .bottom)

            let insertion = removal
                .combined(with: .scale(scale: 20, anchor: .bottom))
                .animation(.spring(
                    response: 0.6,
                    dampingFraction: 0.83,
                    blendDuration: transitionInterval
                ))

            return Images.metawearSide.image()
                .resizable()
                .scaledToFit()
                .alignmentGuide(VerticalAlignment.center) { _ in
                    geo.frame(in: .global).minY
                }
                .frame(maxWidth: .infinity, maxHeight: 250)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .screenInset * 2)
                .transition(.asymmetric(insertion: insertion, removal: removal))
        }

        // MARK: - BG

        private var hueGradient: some View {
            Circle()
                .fill(Color.accentColor)
                .hueRotation(.degrees(-5))
                .blur(radius: 100)
                .offset(y: geo.size.height / 4)
                .transition(.opacity)
        }
    }
}


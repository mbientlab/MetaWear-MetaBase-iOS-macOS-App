// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI
import MetaWear

struct RemoteHelpView: View {

    var showNewToMetaBase: Bool

    @StateObject private var emulatorLog = MWLED.Flash.Emulator(.solid(), .red)
    @StateObject private var emulatorPause = MWLED.Flash.Emulator(.solid(), .yellow)

    @AppStorage(UserDefaults.MetaWear.Keys.didOnboardRemoteMode)
    private var didOnboardRemote = false

    @Environment(\.presentationMode) private var present

    var body: some View {
        VStack(alignment: .leading, spacing: idiom == .macOS ? 15 : 25) {
            #if os(iOS)
            Button("Close", action: { present.wrappedValue.dismiss() })
                .adaptiveFont(.systemHeadline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top)
            #endif

            if showNewToMetaBase { newLabel }

            Text("Remote Control Logging")
                .adaptiveFont(.configureTileTitle)
                .foregroundColor(.myHighlight)

            Text("Use the MetaWear's button to start or pause data recording (without MetaBase), saving battery and flash memory space.")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.configureTileMenu)

            Text("Timing").bold().foregroundColor(.mySecondary)

            Text("When you release the button, logging starts (or pauses). To help you process data, timestamps for button events are logged in a CSV tagged \"switch\".")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.body)

            Text("LED Indicators").bold().foregroundColor(.mySecondary)

            Text("While pressing the button, the LED's color indicates what will happen upon release. Red means logging will start. Yellow means logging will pause. Every five seconds after button release, the LED will blink red or yellow to indicate the current logging state.")
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveFont(.body)

            HStack {
                VStack { log }
                VStack { pause }
            }
            .padding(.top)
        }
        .lineSpacing(5)
        .padding(.horizontal, idiom == .macOS ? 0 : 12)
        .onDisappear { didOnboardRemote = true }
        .environment(\.metaWearModel, .motionS)
    }

    private var newLabel: some View {
        Text("New to MetaBase 5")
            .adaptiveFont(.systemHeadline)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(5)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.myGroupBackground3))
    }

    private let metaWearSize = CGFloat(100)

    @ViewBuilder private var log: some View {

        Capsuled(text: "Logging", textColor: Color(.systemRed))
            .adaptiveFont(.configureTileMenu)

        MetaWearWithLED(
            width: metaWearSize,
            height: metaWearSize,
            ledEmulator: emulatorLog
        )
            .opacity(0.8)
            .onAppear { emulatorLog.emulate() }
    }

    @Environment(\.colorScheme) private var scheme
    @ViewBuilder private var pause: some View {

        Capsuled(text: "Paused", textColor: Color(.systemYellow))
            .adaptiveFont(.configureTileMenu)

        MetaWearWithLED(
            width: metaWearSize,
            height: metaWearSize,
            ledEmulator: emulatorPause
        )
            .opacity(0.8)
            .onAppear { emulatorPause.emulate() }
    }
}

struct Capsuled: View {

    var text: String
    var textColor: Color

    var body: some View {
        Text(text)
            .foregroundColor(textColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule(style: .continuous).foregroundColor(.black.opacity(0.3)))
    }
}

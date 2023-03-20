// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI
import Models
#if DEBUG
import Mocks
#endif
import SwiftUI

public struct DevicesTabView: View {

  public init() {
    #if DEBUG
    let devices: [Device] = [
      .mockUnpaired,
      .mockAnkleLeft,
      .mockAnkleRight,
      .mockWristLeftRecording,
      .mockWristRightRecording,
    ]
    #endif
    self.devices = devices
    self.showSearchableList = devices.count > 15
  }

  private let devices: [Device]
  private let showSearchableList: Bool
  @State private var searchQuery = ""

  public var body: some View {
    // TODO: Detail Screen
    NavigationStack {
      if showSearchableList {
        list
          .searchable(text: $searchQuery)
      } else {
        list
      }
    }
  }

  public var list: some View {
    List {
      let knownLocal = devices.filter(\.state.isKnownLocal)
      let knownRemote = devices.filter(\.state.isKnownRemote)
      let unpaired = devices.filter(\.state.isUnpairedLocal)

      if !knownLocal.isEmpty {
        Section("Nearby") {
          ForEach(knownLocal) { device in
            DeviceRow(device: device)
          }
        }
      }
      if !knownRemote.isEmpty {
        Section("Remembered") {
          ForEach(knownRemote) { device in
            DeviceRow(device: device)
          }
        }
      }
      if !unpaired.isEmpty {
        Section("Unpaired") {
          ForEach(unpaired) { device in
            DeviceRow(device: device)
          }
        }
      }
    }
    .navigationTitle("MetaWear")
  }
}

struct DeviceRow: View {
  let device: Device

  var body: some View {
    // TODO: RSSI
    HStack {
      Text(device.name)
      if device.isRecording {
        Spacer()
        Image(symbol: .recording, variableValue: 1)
          .foregroundColor(.red)
      }
    }
  }
}

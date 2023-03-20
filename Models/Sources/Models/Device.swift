// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import Foundation

public struct Device: Identifiable, Equatable {
  public let id: UUID
  public let isRecording: Bool
  public let name: String
  public let state: State

  public init(id: UUID, isRecording: Bool, name: String, state: State) {
    self.id = id
    self.isRecording = isRecording
    self.name = name
    self.state = state
  }
}

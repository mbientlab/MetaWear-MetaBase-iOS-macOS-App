// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import Foundation

public struct Session: Identifiable, Equatable {
  public let id: UUID
  public let comments: AttributedString
  public let configuration: String
  public let date: Date
  public let devices: Set<String>
  public let location: String
  public let name: String

  public init(id: UUID, comments: AttributedString, configuration: String, date: Date, devices: Set<String>, location: String, name: String) {
    self.id = id
    self.comments = comments
    self.configuration = configuration
    self.date = date
    self.devices = devices
    self.location = location
    self.name = name
  }
}

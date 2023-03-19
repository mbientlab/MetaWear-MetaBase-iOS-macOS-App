import Foundation

public enum SFSymbol: String {
  case devices = "sensor.tag.radiowaves.forward"
  case record = "record.circle"
  case sessions = "books.vertical"
}

extension SFSymbol: CaseIterable {}

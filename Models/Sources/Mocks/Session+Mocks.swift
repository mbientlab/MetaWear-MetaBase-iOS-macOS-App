// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

#if DEBUG
import Models

extension Session {

  public static func blank(id: Session.ID) -> Session {
    Session(
      id: id,
      comments: .init(),
      configuration: .init(),
      date: .init(),
      devices: .init(),
      location: .init(),
      name: .init()
    )
  }

  public static let mockBlank = Session.blank(id: .mockBlank)
}
#endif

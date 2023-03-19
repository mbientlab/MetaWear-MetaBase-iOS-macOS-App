// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import Models

extension Session {

  public static let blank = Session(
    id: .init(),
    comments: .init(),
    configuration: .init(),
    date: .init(),
    devices: .init(),
    location: .init(),
    name: .init()
  )
}

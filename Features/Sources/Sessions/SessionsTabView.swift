// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI
import Models
#if DEBUG
import Mocks
#endif
import SwiftUI

public struct SessionsTabView: View {

  public init() {
    #if DEBUG
    let sourceSessions: [Session] = [
      .mockROM1,
      .mockROM2,
      .mockROM3,
    ]
    #endif
    self.cachedSessions = sourceSessions
    self.sessions = sourceSessions
  }

  private let cachedSessions: [Session]
  @State private var searchQuery = ""
  @State private var selections = Set<Session.ID>()
  @State private var sessions: [Session]
  @State private var sortOrder = [KeyPathComparator(\Session.date)]

  public var body: some View {
    NavigationStack {
      Table(sessions, selection: $selections, sortOrder: $sortOrder) {
        TableColumn("Name", value: \.name)
        TableColumn("Date", value: \.date) {
          Text($0.date, style: .date)
        }
        // Device names / IDs
        // Accelerometer etc
        // Location
        // Length of time
        // Recording scheme
        // File size
      }
      .searchable(text: $searchQuery)
      .navigationTitle("Downloads")
      .toolbar {
        #if os(iOS)
        if !selections.isEmpty {
          ToolbarItem(placement: .bottomBar) {
            Button("Export selected") {}
          }
        }
        #endif
      }
      .onChange(of: sortOrder) { newSortOrder in
        sessions.sort(using: newSortOrder)
      }
      .onChange(of: searchQuery) { newSearchQuery in
        if newSearchQuery.isEmpty {
          sessions = cachedSessions.sorted(using: sortOrder)
          return
        }
        sessions = cachedSessions.filter { $0.name.localizedCaseInsensitiveContains(newSearchQuery) }
      }
    }
  }
}

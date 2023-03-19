// Copyright © 2023 by MBIENTLAB, Inc. All rights reserved.

import MbientlabUI
import SwiftUI

public struct SessionsTabView: View {

  public init() {
    self.cachedSessions = []
    self.sessions = []
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
      }
      .searchable(text: $searchQuery)
      .navigationTitle("Sessions")
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
        sessions = cachedSessions.filter { $0.name.localizedCaseInsensitiveContains(newSearchQuery) }
      }
    }
  }
}

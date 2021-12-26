// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

extension HistoryScreen {

    struct SessionsList: View {

        init(_ factory: UIFactory) {
            _vm = .init(wrappedValue: factory.makePastSessionsVM())
        }

        @StateObject var vm: HistoricalSessionsVM
        @State private var selection: Session? = nil
        @State private var dateWidth = CGFloat(50)
        @State private var timeWidth = CGFloat(50)

        var body: some View {
            VStack {
                Subhead(label: "Prior Sessions")

                List(selection: $selection) {
                    ForEach(vm.sessions) { session in
                        Row(
                            session: session,
                            downloadAction: vm.download(session:),
                            renameAction: vm.rename(session:),
                            deleteAction: vm.delete(session:),
                            isDownloading: vm.isDownloading[session.id] ?? false,
                            dateWidth: dateWidth,
                            timeWidth: timeWidth
                        )
                            .tag(session)
                    }
                }
                .onPreferenceChange(DateWK.self) { dateWidth = $0 }
                .onPreferenceChange(TimeWK.self) { timeWidth = $0 }
                .onDeleteCommand {
                    guard let selection = selection else { return }
                    vm.delete(session: selection)
                }
                .listStyle(.inset)
                .animation(.easeOut, value: vm.sessions.map(\.name))
            }
            .onAppear(perform: vm.onAppear)
        }
    }
}

extension HistoryScreen.SessionsList {

    struct Row: View {

        let session: Session
        let downloadAction: (Session) -> Void
        let renameAction: (Session) -> Void
        let deleteAction: (Session) -> Void
        var isDownloading: Bool
        var dateWidth: CGFloat
        var timeWidth: CGFloat

        @State private var dateString = ""
        @State private var timeString = ""

        var body: some View {
            HStack {
                Text(session.name)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(dateString)
                    .font(.title3)
                    .foregroundColor(.mySecondary)
                    .padding(.trailing, 15)
                    .reportMaxWidth(to: DateWK.self)
                    .frame(minWidth: dateWidth, alignment: .leading)


                Text(timeString)
                    .font(.title3)
                    .foregroundColor(.mySecondary)
                    .padding(.trailing, 15)
                    .reportMaxWidth(to: TimeWK.self)
                    .frame(minWidth: timeWidth, alignment: .leading)

                downloadButton
            }
            .onAppear { dateString = mediumDateFormatter.string(from: session.date) }
            .onAppear { timeString = shortTimeFormatter.string(from: session.date) }
            .padding(3)
            .font(.title3)
            .contextMenu {
                Button("Rename") { renameAction(session) }
                Button("Delete") { deleteAction(session) }
                Divider()
                Button("Download") { downloadAction(session) }
            }
        }

        @ViewBuilder private var downloadButton: some View {
            if isDownloading {
                ProgressSpinner()

            }  else {
                Button { downloadAction(session) } label: {
                    SFSymbol.download.image()
                        .font(.title3.weight(.medium))
                }
                .buttonStyle(HoverButtonStyle())
            }
        }


    }
}

fileprivate struct DateWK: MaxWidthKey {
    public static var defaultValue: CGFloat = 50
}


fileprivate struct TimeWK: MaxWidthKey {
    public static var defaultValue: CGFloat = 50
}

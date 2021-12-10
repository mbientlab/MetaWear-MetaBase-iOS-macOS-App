////Copyright
//
//import SwiftUI
//
//struct ProgressScreen: View {
//
//    @EnvironmentObject private var routing: Routing
//    private var title: String { true ? "Streaming" : "Configuring Loggers" }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            Header(
//                text: title,
//                deviceIcons: 0,
//                showBackButton: false
//            )
//
//            List {
//                TaskRow(name: "Example 1", progress: 0.25)
//                TaskRow(name: "Example 1", progress: 0)
//            }
//
//            CTAButton("Cancel") {  }
//            .frame(maxWidth: .infinity, alignment: .center)
//        }
//        .padding(.bottom, .screenInset)
//        .padding(.horizontal, .screenInset)
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//    }
//}
//
//extension ProgressScreen {
//
//    struct TaskRow: View {
//
//        let name: String
//        let progress: CGFloat
//
//        var body: some View {
//            HStack(alignment: .firstTextBaseline) {
//                Text(name)
//                    .font(.headline)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .lineLimit(2)
//                    .padding(.trailing,  .screenInset)
//
//                ProgressBar(value: progress)
//                    .frame(width: 200, height: 8)
//            }
//        }
//    }
//}

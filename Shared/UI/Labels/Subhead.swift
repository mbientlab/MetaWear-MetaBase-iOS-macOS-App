// Copyright 2021 MbientLab Inc. All rights reserved. See LICENSE.MD.

import SwiftUI

struct Subhead<T: View>: View {

    internal init(label: String, trailing: @escaping () -> T) {
        self.label = label
        self.trailing = trailing
    }

    internal init(label: String) where T == Spacer {
        self.label = label
        self.trailing = { Spacer() }
    }

    let label: String
    let trailing: () -> T

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .font(.title2)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .padding(.horizontal, 4)

                Spacer()
                
                trailing()
            }

            Divider()
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
    }
}
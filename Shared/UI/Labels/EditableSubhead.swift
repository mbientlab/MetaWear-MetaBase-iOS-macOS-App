// Copyright 2022 MbientLab Inc. All rights reserved. See LICENSE.MD.

import mbientSwiftUI

struct EditableSubhead<T: View>: View {

    internal init(label: Binding<String>, placeholder: String, trailing: @escaping () -> T) {
        self.label = label
        self.trailing = trailing
        self.placeholder = placeholder
    }

    internal init(label: Binding<String>, placeholder: String) where T == Spacer {
        self.label = label
        self.trailing = { Spacer() }
        self.placeholder = placeholder
    }

    var label: Binding<String>
    var placeholder: String
    let trailing: () -> T

    var body: some View {
        VStack(alignment: .leading) {
            HStack {

                ResigningTextField(placeholderText: placeholder,
                                   initialText: label.wrappedValue,
                                   config: .largeDeviceStyle(),
                                   onCommit: { label.wrappedValue = $0 })
                    .padding(.horizontal, 4)
                    .offset(y: 2)

                Spacer()

                trailing()
            }

            Divider()
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
    }
}

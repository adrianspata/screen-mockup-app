import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            PasteButton(payloadType: Data.self) { _ in }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(.blue)
                .frame(width: 56, height: 56)
        }
    }
}

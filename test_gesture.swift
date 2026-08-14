import SwiftUI
struct TestView: View {
    var body: some View {
        Color.red.gesture(
            MagnifyGesture().onChanged { value in
                let _ = value.startLocation
            }
        )
    }
}

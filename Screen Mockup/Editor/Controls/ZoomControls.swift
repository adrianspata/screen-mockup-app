import SwiftUI

struct ZoomControls: View {
    let document: MockupDocument
    @State private var resetFeedbackTrigger = false
    
    var body: some View {
        VStack(spacing: 24) {
            let scaleBinding = Binding<CGFloat>(
                get: {
                    if let id = document.selectedElementID,
                       let element = document.elements.first(where: { $0.id == id }) {
                        return element.transform.scale
                    }
                    return 1.0
                },
                set: { newValue in
                    if let id = document.selectedElementID,
                       let index = document.elements.firstIndex(where: { $0.id == id }) {
                        document.elements[index].transform.scale = newValue
                    }
                }
            )
            
            // Prominent percentage
            let percentage = Int(scaleBinding.wrappedValue * 100)
            Text("\(percentage)%")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white)
            
            // Slider with icons
            HStack {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Slider(value: scaleBinding, in: 0.25...2.0)
                .accentColor(.screenyOrange)
                
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
            
            // Minimal Reset Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    document.resetTransform()
                }
                resetFeedbackTrigger.toggle()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.controlBackground)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
        .sensoryFeedback(.selection, trigger: resetFeedbackTrigger)
    }
}

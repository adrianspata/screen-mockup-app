import SwiftUI

struct ZoomControls: View {
    let document: MockupDocument
    @State private var resetFeedbackTrigger = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Prominent percentage
            let percentage = Int(document.scale * 100)
            Text("\(percentage)%")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white)
            
            // Slider with icons
            HStack {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Slider(value: Binding(
                    get: { document.scale },
                    set: { document.scale = $0 }
                ), in: 0.25...2.0)
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

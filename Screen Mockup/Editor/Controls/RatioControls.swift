import SwiftUI

struct RatioControls: View {
    @Bindable var document: MockupDocument
    @State private var feedbackTrigger = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Orientation Toggle
            HStack(spacing: 8) {
                ForEach(CanvasOrientation.allCases, id: \.self) { orientation in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            document.canvasOrientation = orientation
                        }
                        feedbackTrigger.toggle()
                    }) {
                        Text(orientation.rawValue)
                            .font(.subheadline)
                            .fontWeight(document.canvasOrientation == orientation ? .medium : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(document.canvasOrientation == orientation ? Color.controlBackground : Color.clear)
                            .foregroundColor(document.canvasOrientation == orientation ? .screenyOrange : .gray)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(document.canvasOrientation == orientation ? Color.screenyOrange : Color.gray.opacity(0.3), lineWidth: document.canvasOrientation == orientation ? 1 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Ratio Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CanvasRatio.allCases, id: \.self) { ratio in
                        let isActive = document.canvasRatio == ratio
                        let firstMedia = document.elements.compactMap { el -> MediaReference? in
                            if case .device(let data) = el.content { return data.media }
                            return nil
                        }.first
                        let ratioValue = ratio.ratio(for: firstMedia, orientation: document.canvasOrientation) ?? 1.0
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                document.canvasRatio = ratio
                            }
                            if !isActive {
                                feedbackTrigger.toggle()
                            }
                        }) {
                            VStack(spacing: 8) {
                                // Simple visual representation of the ratio
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isActive ? Color.screenyOrange.opacity(0.2) : Color.controlBackground)
                                    .frame(width: ratioValue >= 1.0 ? 30 : 30 * ratioValue,
                                           height: ratioValue >= 1.0 ? 30 / ratioValue : 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(isActive ? Color.screenyOrange : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
                                    )
                                    .frame(width: 30, height: 30) // Fixed bounds for layout consistency
                                
                                Text(ratio.rawValue)
                                    .font(.caption)
                                    .fontWeight(isActive ? .semibold : .regular)
                                    .foregroundColor(isActive ? .white : .gray)
                            }
                            .frame(width: 70, height: 90)
                            .background(Color.controlBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isActive ? Color.screenyOrange : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }
}

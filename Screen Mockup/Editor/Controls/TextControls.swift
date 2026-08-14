import SwiftUI

struct TextControls: View {
    @Bindable var document: MockupDocument
    
    let fonts = [
        "System",
        "System Serif",
        "System Rounded",
        "System Mono",
        "Helvetica Neue",
        "Arial",
        "Avenir Next",
        "Futura",
        "Optima",
        "Chalkboard SE"
    ]
    
    let colors: [Color] = [.white, .black, .red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        VStack(spacing: 12) {
            if let selectedID = document.selectedElementID,
               let index = document.elements.firstIndex(where: { $0.id == selectedID }),
               case .text(var textData) = document.elements[index].content {
                
                // Color Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: textData.color == color ? 3 : 0)
                                        .padding(-4)
                                )
                                .onTapGesture {
                                    textData.color = color
                                    document.elements[index].content = .text(textData)
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Font Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(fonts, id: \.self) { fontName in
                            Text("Aa")
                                .font(font(for: fontName))
                                .frame(width: 60, height: 60)
                                .background(textData.fontName == fontName ? Color.screenyOrange.opacity(0.8) : Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: textData.fontName == fontName ? 2 : 0)
                                )
                                .foregroundColor(.white)
                                .onTapGesture {
                                    textData.fontName = fontName
                                    document.elements[index].content = .text(textData)
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Font Size Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Font Size")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(document.elements[index].scale * 100))")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: Binding(
                        get: { document.elements[index].scale },
                        set: { newValue in
                            document.elements[index].scale = newValue
                        }
                    ), in: 0.02...1.0, step: 0.01)
                    .tint(.screenyOrange)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    
    
    private func font(for name: String) -> Font {
        switch name {
        case "System": return .system(size: 24)
        case "System Serif": return .system(size: 24, design: .serif)
        case "System Rounded": return .system(size: 24, design: .rounded)
        case "System Mono": return .system(size: 24, design: .monospaced)
        default: return .custom(name, size: 24)
        }
    }
}

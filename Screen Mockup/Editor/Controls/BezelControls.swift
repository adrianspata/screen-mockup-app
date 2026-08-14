import SwiftUI

struct BezelControls: View {
    @Bindable var document: MockupDocument
    @State private var feedbackTrigger = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Style")
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    ForEach(BezelStyle.allCases, id: \.self) { style in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                document.bezelStyle = style
                            }
                            feedbackTrigger.toggle()
                        }) {
                            HStack {
                                Text(style.rawValue)
                                if document.bezelStyle == style {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(document.bezelStyle.rawValue)
                            .font(.body)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                
            Toggle("Show Status Bar", isOn: $document.showStatusBar)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .tint(.screenyOrange)
                
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding(.horizontal, 32)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }
}

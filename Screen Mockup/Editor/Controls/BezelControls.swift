import SwiftUI

struct BezelControls: View {
    @Bindable var document: MockupDocument
    @State private var feedbackTrigger = false
    
    var body: some View {
        let isDeviceSelected = document.selectedElementID != nil && document.elements.first(where: { $0.id == document.selectedElementID })?.content.isDevice == true
        
        VStack(spacing: 0) {
            HStack {
                Text("Style")
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    ForEach(BezelStyle.allCases, id: \.self) { style in
                        Button(action: {
                            if let id = document.selectedElementID,
                               let index = document.elements.firstIndex(where: { $0.id == id }),
                               case .device(var data) = document.elements[index].content {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    data.bezelStyle = style
                                    document.elements[index].content = .device(data)
                                }
                                feedbackTrigger.toggle()
                            }
                        }) {
                            HStack {
                                Text(style.rawValue)
                                if let id = document.selectedElementID,
                                   let element = document.elements.first(where: { $0.id == id }),
                                   case .device(let data) = element.content,
                                   data.bezelStyle == style {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        let currentStyle = (document.elements.first(where: { $0.id == document.selectedElementID })?.content.deviceData?.bezelStyle) ?? .none
                        Text(currentStyle.rawValue)
                            .font(.body)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .disabled(!isDeviceSelected)
            }
            .padding(.vertical, 16)
            .opacity(isDeviceSelected ? 1.0 : 0.5)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                
            let statusBarBinding = Binding<Bool>(
                get: {
                    if let id = document.selectedElementID,
                       let element = document.elements.first(where: { $0.id == id }),
                       case .device(let data) = element.content {
                        return data.showStatusBar
                    }
                    return false
                },
                set: { newValue in
                    if let id = document.selectedElementID,
                       let index = document.elements.firstIndex(where: { $0.id == id }),
                       case .device(var data) = document.elements[index].content {
                        data.showStatusBar = newValue
                        document.elements[index].content = .device(data)
                    }
                }
            )
                
            Toggle("Show Status Bar", isOn: statusBarBinding)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .tint(.screenyOrange)
                .disabled(!isDeviceSelected)
                .opacity(isDeviceSelected ? 1.0 : 0.5)
                
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding(.horizontal, 32)
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }
}

extension CanvasElement.ElementContent {
    var isDevice: Bool {
        if case .device = self { return true }
        return false
    }
    var deviceData: DeviceElementData? {
        if case .device(let data) = self { return data }
        return nil
    }
}

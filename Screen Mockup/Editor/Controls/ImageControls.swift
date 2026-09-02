import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImageControls: View {
    let session: ProjectSession
    var document: MockupDocument { session.document }
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showFileImporter = false
    
    var isImageSelected: Bool {
        guard let id = document.selectedElementID,
              let element = document.elements.first(where: { $0.id == id }) else {
            return false
        }
        if case .image = element.content { return true }
        return false
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    ControlItem(icon: "photo.on.rectangle", label: "Photos")
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await ImageImporter.importImage(uiImage, into: session)
                        }
                    }
                }
                
                Button(action: { showFileImporter = true }) {
                    ControlItem(icon: "folder", label: "Files")
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
                    if case .success(let url) = result {
                        if url.startAccessingSecurityScopedResource() {
                            let securedURL = url // Capture for async context
                            Task {
                                defer { securedURL.stopAccessingSecurityScopedResource() }
                                if let data = try? Data(contentsOf: securedURL), let uiImage = UIImage(data: data) {
                                    await ImageImporter.importImage(uiImage, into: session)
                                }
                            }
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    PasteButton(payloadType: Data.self) { dataItems in
                        Task { @MainActor in
                            if let data = dataItems.first, let uiImage = UIImage(data: data) {
                                await ImageImporter.importImage(uiImage, into: session)
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .tint(Color.controlBackground)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    // Ensure the PasteButton scales nicely
                    .frame(height: 56)
                    
                    Text("Paste")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal)
            
            if let id = document.selectedElementID,
               let index = document.elements.firstIndex(where: { $0.id == id }),
               case .image(var ref) = document.elements[index].content {
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Border Radius")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(ref.cornerRadius)) px")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: Binding(
                        get: { ref.cornerRadius },
                        set: { newValue in
                            ref.cornerRadius = newValue
                            document.elements[index].content = .image(ref)
                        }
                    ), in: 0...200, step: 1)
                    .tint(Color.screenyOrange)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Button(role: .destructive, action: {
                    withAnimation {
                        document.elements.removeAll(where: { $0.id == id })
                        document.selectedElementID = nil
                    }
                }) {
                    Label("Delete Image", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 20)
    }
}

private struct ControlItem: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

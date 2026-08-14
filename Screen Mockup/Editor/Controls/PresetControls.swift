import SwiftUI

struct PresetControls: View {
    @Bindable var document: MockupDocument
    @State private var feedbackTrigger = false
    @State private var store = PresetStore()
    
    @State private var showingSaveAlert = false
    @State private var newPresetName = ""
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Current State
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.controlBackground)
                        .frame(width: 80, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.screenyOrange, lineWidth: 2)
                        )
                        .overlay(
                            Text("Current")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
                
                // Save Preset Button
                Button(action: {
                    newPresetName = ""
                    showingSaveAlert = true
                }) {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.controlBackground)
                            .frame(width: 80, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                Divider().frame(height: 80)
                
                // Saved Presets
                ForEach(store.savedPresets) { preset in
                    let isActive = document.matches(preset: preset)
                    
                    Menu {
                        Button(role: .destructive) {
                            store.deletePreset(id: preset.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        presetButton(preset: preset, isActive: isActive)
                    } primaryAction: {
                        applyPreset(preset, isActive: isActive)
                    }
                }
                
                if !store.savedPresets.isEmpty {
                    Divider().frame(height: 80)
                }
                
                // Built-in Presets
                ForEach(MockupPreset.allBuiltIns) { preset in
                    let isActive = document.matches(preset: preset)
                    
                    Button(action: {
                        applyPreset(preset, isActive: isActive)
                    }) {
                        presetButton(preset: preset, isActive: isActive)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
        .alert("Save Preset", isPresented: $showingSaveAlert) {
            TextField("Preset Name", text: $newPresetName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !newPresetName.isEmpty {
                    let snapshot = MockupPreset(
                        id: "", name: "",
                        background: document.background,
                        backgroundOpacity: document.backgroundOpacity,
                        canvasRatio: document.canvasRatio,
                        canvasOrientation: document.canvasOrientation,
                        bezelStyle: document.bezelStyle,
                        showStatusBar: document.showStatusBar,
                        scale: document.scale,
                        normalizedOffset: document.normalizedOffset
                    )
                    store.savePreset(snapshot, name: newPresetName)
                }
            }
        }
    }
    
    private func presetButton(preset: MockupPreset, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.controlBackground)
                .frame(width: 80, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.screenyOrange : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Text(preset.name)
                        .font(.caption)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundColor(isActive ? .white : .gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                )
        }
    }
    
    private func applyPreset(_ preset: MockupPreset, isActive: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            document.apply(preset: preset)
        }
        if !isActive {
            feedbackTrigger.toggle()
        }
    }
}

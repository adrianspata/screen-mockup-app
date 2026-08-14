import Foundation
import SwiftUI

struct SavedPreset: Codable, Identifiable {
    let id: String
    var name: String
    
    // Background
    let backgroundType: String // "none", "solid", "gradient", "image"
    let solidColorHex: String?
    let gradientStartHex: String?
    let gradientEndHex: String?
    let backgroundOpacity: Double
    
    // Other Settings
    let canvasRatio: CanvasRatio
    let canvasOrientation: CanvasOrientation
    let bezelStyle: BezelStyle
    let showStatusBar: Bool
    
    // Transform
    let scale: CGFloat
    let normalizedOffsetX: CGFloat
    let normalizedOffsetY: CGFloat
    
    // Fallback for image background since we don't save the image data in Phase 7.2
    let hasImageBackgroundFallback: Bool
}

@Observable
final class PresetStore {
    var savedPresets: [MockupPreset] = []
    
    private let defaultsKey = "screen_mockup_saved_presets"
    
    init() {
        load()
    }
    
    func savePreset(_ preset: MockupPreset, name: String) {
        let newPreset = MockupPreset(
            id: UUID().uuidString,
            name: name,
            background: preset.background,
            backgroundOpacity: preset.backgroundOpacity,
            canvasRatio: preset.canvasRatio,
            canvasOrientation: preset.canvasOrientation,
            bezelStyle: preset.bezelStyle,
            showStatusBar: preset.showStatusBar,
            scale: preset.scale,
            normalizedOffset: preset.normalizedOffset
        )
        savedPresets.append(newPreset)
        persist()
    }
    
    func deletePreset(id: String) {
        savedPresets.removeAll { $0.id == id }
        persist()
    }
    
    private func persist() {
        let codablePresets = savedPresets.map { toCodable($0) }
        if let data = try? JSONEncoder().encode(codablePresets) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let codablePresets = try? JSONDecoder().decode([SavedPreset].self, from: data) {
            savedPresets = codablePresets.map { fromCodable($0) }
        }
    }
    
    private func toCodable(_ preset: MockupPreset) -> SavedPreset {
        var bgType = "none"
        var solidHex: String? = nil
        var gradStartHex: String? = nil
        var gradEndHex: String? = nil
        var hasImage = false
        
        switch preset.background {
        case .none:
            bgType = "none"
        case .solid(let color):
            bgType = "solid"
            solidHex = color.toHex()
        case .gradient(let start, let end):
            bgType = "gradient"
            gradStartHex = start.toHex()
            gradEndHex = end.toHex()
        case .image(_):
            bgType = "image"
            hasImage = true
        }
        
        return SavedPreset(
            id: preset.id,
            name: preset.name,
            backgroundType: bgType,
            solidColorHex: solidHex,
            gradientStartHex: gradStartHex,
            gradientEndHex: gradEndHex,
            backgroundOpacity: preset.backgroundOpacity,
            canvasRatio: preset.canvasRatio,
            canvasOrientation: preset.canvasOrientation,
            bezelStyle: preset.bezelStyle,
            showStatusBar: preset.showStatusBar,
            scale: preset.scale,
            normalizedOffsetX: preset.normalizedOffset.width,
            normalizedOffsetY: preset.normalizedOffset.height,
            hasImageBackgroundFallback: hasImage
        )
    }
    
    private func fromCodable(_ saved: SavedPreset) -> MockupPreset {
        var background: BackgroundStyle = .none
        
        switch saved.backgroundType {
        case "solid":
            if let hex = saved.solidColorHex, let color = Color(hex: hex) {
                background = .solid(color)
            }
        case "gradient":
            if let startHex = saved.gradientStartHex, let startColor = Color(hex: startHex),
               let endHex = saved.gradientEndHex, let endColor = Color(hex: endHex) {
                background = .gradient(startColor, endColor)
            }
        case "image":
            // Limitation documented in Phase 7.2: Background image data is not serialized.
            // We preserve the mode, but it falls back to none unless replaced.
            background = .none
        default:
            background = .none
        }
        
        return MockupPreset(
            id: saved.id,
            name: saved.name,
            background: background,
            backgroundOpacity: saved.backgroundOpacity,
            canvasRatio: saved.canvasRatio,
            canvasOrientation: saved.canvasOrientation,
            bezelStyle: saved.bezelStyle,
            showStatusBar: saved.showStatusBar,
            scale: saved.scale,
            normalizedOffset: CGSize(width: saved.normalizedOffsetX, height: saved.normalizedOffsetY)
        )
    }
}

// Simple Color <-> Hex extensions for persistence
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if hexSanitized.count == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if hexSanitized.count == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }
}

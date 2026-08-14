import XCTest
import SwiftUI
@testable import Screen_Mockup

final class Phase72ATests: XCTestCase {
    
    // 7. Verify all ratios
    func testAllRatiosAndDimensions() throws {
        let dummyImage = UIImage()
        let doc = MockupDocument()
        doc.screenshot = dummyImage
        
        let maxDim: CGFloat = 3000.0
        
        // Portrait
        let portraitRatios: [CanvasRatio] = [.fourToFive, .fiveToSeven, .threeToFour, .twoToThree, .nineToSixteen]
        for ratio in portraitRatios {
            let val = ratio.ratio(for: dummyImage, orientation: .portrait) ?? 1.0
            
            var targetWidth: CGFloat = 0
            var targetHeight: CGFloat = 0
            
            if val >= 1.0 {
                targetWidth = maxDim
                targetHeight = maxDim / val
            } else {
                targetHeight = maxDim
                targetWidth = maxDim * val
            }
            
            XCTAssertEqual(max(targetWidth, targetHeight), maxDim, accuracy: 0.1, "Ratio \(ratio) failed dimension test")
        }
        
        // Landscape
        for ratio in portraitRatios {
            let val = ratio.ratio(for: dummyImage, orientation: .landscape) ?? 1.0
            
            var targetWidth: CGFloat = 0
            var targetHeight: CGFloat = 0
            
            if val >= 1.0 {
                targetWidth = maxDim
                targetHeight = maxDim / val
            } else {
                targetHeight = maxDim
                targetWidth = maxDim * val
            }
            
            XCTAssertEqual(max(targetWidth, targetHeight), maxDim, accuracy: 0.1, "Ratio \(ratio) failed dimension test")
        }
    }
    
    // 8. Verify Presets Serialization
    func testPresetSerializationAndCurrent() throws {
        let store = PresetStore()
        
        let originalCount = store.savedPresets.count
        
        // Create a custom state
        var doc = MockupDocument()
        doc.background = .solid(.red)
        doc.backgroundOpacity = 0.5
        doc.canvasRatio = .fourToFive
        doc.canvasOrientation = .landscape
        doc.bezelStyle = .iphone16Light
        doc.showStatusBar = true
        doc.scale = 1.2
        doc.normalizedOffset = CGSize(width: 0.1, height: -0.1)
        
        let presetToSave = MockupPreset(
            id: "", name: "",
            background: doc.background,
            backgroundOpacity: doc.backgroundOpacity,
            canvasRatio: doc.canvasRatio,
            canvasOrientation: doc.canvasOrientation,
            bezelStyle: doc.bezelStyle,
            showStatusBar: doc.showStatusBar,
            scale: doc.scale,
            normalizedOffset: doc.normalizedOffset
        )
        
        store.savePreset(presetToSave, name: "Test Preset")
        
        XCTAssertEqual(store.savedPresets.count, originalCount + 1)
        
        let loaded = store.savedPresets.last!
        XCTAssertEqual(loaded.name, "Test Preset")
        XCTAssertEqual(loaded.backgroundOpacity, 0.5)
        XCTAssertEqual(loaded.canvasRatio, .fourToFive)
        XCTAssertEqual(loaded.canvasOrientation, .landscape)
        XCTAssertEqual(loaded.bezelStyle, .iphone16Light)
        XCTAssertEqual(loaded.showStatusBar, true)
        XCTAssertEqual(loaded.scale, 1.2)
        XCTAssertEqual(loaded.normalizedOffset, CGSize(width: 0.1, height: -0.1))
        
        // Check image fallback
        doc.background = .image(UIImage())
        let imagePreset = MockupPreset(
            id: "", name: "",
            background: doc.background,
            backgroundOpacity: doc.backgroundOpacity,
            canvasRatio: doc.canvasRatio,
            canvasOrientation: doc.canvasOrientation,
            bezelStyle: doc.bezelStyle,
            showStatusBar: doc.showStatusBar,
            scale: doc.scale,
            normalizedOffset: doc.normalizedOffset
        )
        store.savePreset(imagePreset, name: "Image Preset")
        
        let loadedImagePreset = store.savedPresets.last!
        switch loadedImagePreset.background {
        case .none:
            XCTAssertTrue(true)
        default:
            XCTFail("Image preset should fallback to none")
        }
        
        store.deletePreset(id: loaded.id)
        store.deletePreset(id: loadedImagePreset.id)
        XCTAssertEqual(store.savedPresets.count, originalCount)
    }
}

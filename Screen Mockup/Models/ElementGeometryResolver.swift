import Foundation
import CoreGraphics
import SwiftUI

enum ElementGeometryResolver {
    /// Computes the unscaled "base size" of an element in canvas pixel coordinates.
    static func baseSize(for content: CanvasElement.ElementContent, in canvasSize: CGSize) -> CGSize {
        let canvasAspect = canvasSize.width / max(1, canvasSize.height)
        
        switch content {
        case .device(let data):
            let screenshotAspect: CGFloat
            if data.bezelStyle == .none {
                let size = data.media.pixelSize ?? .zero
                screenshotAspect = size.height > 0 ? (size.width / size.height) : 1.0
            } else if let spec = data.bezelStyle.spec {
                screenshotAspect = spec.imageAspect
            } else {
                screenshotAspect = 9.0 / 16.0
            }
            
            let unscaledW = screenshotAspect > canvasAspect ? canvasSize.width : canvasSize.height * screenshotAspect
            let unscaledH = screenshotAspect > canvasAspect ? canvasSize.width / screenshotAspect : canvasSize.height
            return CGSize(width: unscaledW, height: unscaledH)
            
        case .image(let ref):
            let size = ref.pixelSize ?? CGSize(width: 1, height: 1)
            let aspect = size.width / max(1, size.height)
            let unscaledW = canvasSize.width
            let unscaledH = canvasSize.width / aspect
            return CGSize(width: unscaledW, height: unscaledH)
            
        case .text(let textData):
            let defaultFontSize = canvasSize.width
            let uiFont: UIFont
            switch textData.fontName {
            case "System": uiFont = .systemFont(ofSize: defaultFontSize)
            case "System Serif": uiFont = .systemFont(ofSize: defaultFontSize)
            case "System Rounded": uiFont = .systemFont(ofSize: defaultFontSize)
            case "System Mono": uiFont = .monospacedSystemFont(ofSize: defaultFontSize, weight: .regular)
            default: uiFont = UIFont(name: textData.fontName, size: defaultFontSize) ?? .systemFont(ofSize: defaultFontSize)
            }
            let nsString = textData.string as NSString
            let rect = nsString.boundingRect(with: CGSize(width: canvasSize.width, height: .greatestFiniteMagnitude),
                                             options: .usesLineFragmentOrigin,
                                             attributes: [.font: uiFont],
                                             context: nil)
            return rect.size
            
        case .sfSymbol:
            let size = canvasSize.width * 0.2
            return CGSize(width: size, height: size)
        }
    }
    
    /// Computes the visual bounds (size after scaling) in canvas pixel coordinates.
    static func visualSize(for element: CanvasElement, in canvasSize: CGSize) -> CGSize {
        let base = baseSize(for: element.content, in: canvasSize)
        return CGSize(width: base.width * element.transform.scale, height: base.height * element.transform.scale)
    }
    
    /// Computes the normalized SnapGeometry (AABB) taking rotation into account
    static func snapGeometry(for element: CanvasElement, in canvasSize: CGSize) -> SnapGeometry {
        let visual = visualSize(for: element, in: canvasSize)
        
        let wNorm = visual.width / canvasSize.width
        let hNorm = visual.height / canvasSize.height
        
        let cx = element.transform.normalizedPosition.x
        let cy = element.transform.normalizedPosition.y
        
        let rad = element.transform.rotationDegrees * .pi / 180.0
        let cosA = cos(rad)
        let sinA = sin(rad)
        
        // Corners relative to center
        let hw = wNorm / 2
        let hh = hNorm / 2
        
        let corners: [(CGFloat, CGFloat)] = [
            (-hw, -hh),
            (hw, -hh),
            (hw, hh),
            (-hw, hh)
        ]
        
        var minX: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for (x, y) in corners {
            let rx = x * cosA - y * sinA
            let ry = x * sinA + y * cosA
            
            let nx = cx + rx
            let ny = cy + ry
            
            if nx < minX { minX = nx }
            if nx > maxX { maxX = nx }
            if ny < minY { minY = ny }
            if ny > maxY { maxY = ny }
        }
        
        return SnapGeometry(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
}

import Foundation
import CoreGraphics
import SwiftUI

struct ElementTransform: Equatable, Sendable {
    var normalizedPosition: CGPoint
    var scale: CGFloat
    var rotationDegrees: Double
    var opacity: Double
}

struct DeviceElementData: Equatable, Sendable {
    var media: MediaReference
    var bezelStyle: BezelStyle
    var showStatusBar: Bool
}

struct CanvasElement: Identifiable, Equatable {
    let id: UUID
    var content: ElementContent
    var transform: ElementTransform
    var zIndex: Int
    var isLocked: Bool
    var isHidden: Bool
    
    struct TextData: Equatable, Sendable {
        var string: String
        var fontName: String
        var color: Color
        
        static func == (lhs: TextData, rhs: TextData) -> Bool {
            lhs.string == rhs.string && lhs.fontName == rhs.fontName && lhs.color == rhs.color
        }
    }
    
    enum ElementContent: Equatable {
        case device(DeviceElementData)
        case image(MediaReference)
        case text(TextData)
        case sfSymbol
    }
    
    init(
        id: UUID = UUID(),
        content: ElementContent,
        transform: ElementTransform = ElementTransform(normalizedPosition: CGPoint(x: 0.5, y: 0.5), scale: 1.0, rotationDegrees: 0.0, opacity: 1.0),
        zIndex: Int = 0,
        isLocked: Bool = false,
        isHidden: Bool = false
    ) {
        self.id = id
        self.content = content
        self.transform = transform
        self.zIndex = zIndex
        self.isLocked = isLocked
        self.isHidden = isHidden
    }
}

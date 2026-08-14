import Foundation
import CoreGraphics
import SwiftUI

struct CanvasElement: Identifiable, Equatable {
    let id: UUID
    var content: ElementContent
    var normalizedPosition: CGPoint
    var scale: CGFloat
    var zIndex: Int
    
    struct TextData: Equatable {
        var string: String
        var fontName: String // System font name or generic like "System"
        var color: Color // Using SwiftUI Color, requires custom Equatable or just storing hex. We will use Color.
        
        static func == (lhs: TextData, rhs: TextData) -> Bool {
            lhs.string == rhs.string && lhs.fontName == rhs.fontName && lhs.color == rhs.color
        }
    }
    
    enum ElementContent: Equatable {
        case image(ImageReference)
        case text(TextData)
        case sfSymbol
    }
    
    init(id: UUID = UUID(), content: ElementContent, normalizedPosition: CGPoint = CGPoint(x: 0.5, y: 0.5), scale: CGFloat = 1.0, zIndex: Int = 0) {
        self.id = id
        self.content = content
        self.normalizedPosition = normalizedPosition
        self.scale = scale
        self.zIndex = zIndex
    }
}

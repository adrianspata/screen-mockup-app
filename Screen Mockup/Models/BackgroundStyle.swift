import SwiftUI

enum BackgroundStyle: Equatable {
    case none
    case solid(Color)
    case gradient(Color, Color)
    case image(UIImage)
    
    // Custom equatable to handle UIImage properly
    static func == (lhs: BackgroundStyle, rhs: BackgroundStyle) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.solid(lColor), .solid(rColor)):
            return lColor == rColor
        case let (.gradient(lStart, lEnd), .gradient(rStart, rEnd)):
            return lStart == rStart && lEnd == rEnd
        case let (.image(lImage), .image(rImage)):
            return lImage === rImage
        default:
            return false
        }
    }
}

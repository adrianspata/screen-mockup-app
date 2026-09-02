import CoreGraphics
import UIKit

enum CanvasOrientation: String, CaseIterable, Codable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}

enum CanvasRatio: String, CaseIterable, Codable {
    case original = "Original"
    case square = "1:1"
    case fourToFive = "4:5"
    case fiveToSeven = "5:7"
    case threeToFour = "3:4"
    case twoToThree = "2:3"
    case nineToSixteen = "9:16"
    
    /// Calculates the aspect ratio (width / height) based on the ratio and orientation.
    func ratio(for media: MediaReference?, orientation: CanvasOrientation) -> CGFloat? {
        switch self {
        case .original:
            guard let media = media, let size = media.pixelSize else { return nil }
            if size.height == 0 { return 1.0 }
            
            // If the user wants original ratio, but it's rotated?
            // "Original" implies we follow the native media aspect.
            // If we rotate the canvas, we should invert the media aspect.
            let mediaAspect = size.width / size.height
            if orientation == .landscape {
                return 1.0 / mediaAspect
            }
            return mediaAspect
        case .square:
            return 1.0
        case .fourToFive:
            return orientation == .landscape ? 5.0 / 4.0 : 4.0 / 5.0
        case .fiveToSeven:
            return orientation == .landscape ? 7.0 / 5.0 : 5.0 / 7.0
        case .threeToFour:
            return orientation == .landscape ? 4.0 / 3.0 : 3.0 / 4.0
        case .twoToThree:
            return orientation == .landscape ? 3.0 / 2.0 : 2.0 / 3.0
        case .nineToSixteen:
            return orientation == .landscape ? 16.0 / 9.0 : 9.0 / 16.0
        }
    }
}

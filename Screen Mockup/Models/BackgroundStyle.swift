import SwiftUI

enum BackgroundStyle: Equatable {
    case none
    case solid(Color)
    case gradient(Color, Color)
    case image(MediaReference)
}

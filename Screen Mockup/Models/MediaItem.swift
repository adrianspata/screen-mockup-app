import SwiftUI
import AVFoundation

enum MediaItem: Equatable {
    case image(UIImage)
    case video(URL)
    
    var size: CGSize {
        switch self {
        case .image(let uiImage):
            return uiImage.size
        case .video(let url):
            guard let track = AVURLAsset(url: url).tracks(withMediaType: .video).first else { return .zero }
            let size = track.naturalSize.applying(track.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        }
    }
}

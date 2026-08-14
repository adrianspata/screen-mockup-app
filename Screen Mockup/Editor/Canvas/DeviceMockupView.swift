
import SwiftUI

struct DeviceMockupView: View {
    let media: MediaItem
    let style: BezelStyle
    let showStatusBar: Bool
    
    @ViewBuilder
    private var mediaContent: some View {
        switch media {
        case .image(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
        case .video(let url):
            VideoPlayerView(url: url)
        }
    }
    
    var body: some View {
        if style == .none {
            mediaContent
                .aspectRatio(contentMode: .fit)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        } else if let spec = style.spec {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                let innerW = w * (1.0 - spec.screenLeftInsetRatio - spec.screenRightInsetRatio)
                let innerH = h * (1.0 - spec.screenTopInsetRatio - spec.screenBottomInsetRatio)
                
                let offsetX = w * (spec.screenLeftInsetRatio - spec.screenRightInsetRatio) / 2.0
                let offsetY = h * (spec.screenTopInsetRatio - spec.screenBottomInsetRatio) / 2.0
                
                let innerCR = w * spec.innerCornerRadiusRatio
                
                ZStack {
                    // Inner Screen Area (Screenshot goes behind the bezel)
                    mediaContent
                        .aspectRatio(contentMode: .fill) // Aspect Fill into screen mask
                        .frame(width: innerW, height: innerH)
                        .clipShape(RoundedRectangle(cornerRadius: innerCR, style: .continuous))
                        .overlay(alignment: .top) {
                            if showStatusBar {
                                StatusBarView(spec: spec, isDarkContent: !style.isDark) // Approximate contrast
                                    .frame(width: innerW)
                                    // Status bar offset relative to the *screen* width (innerW)
                                    .offset(y: innerW * spec.statusBarElementTopInsetRatio)
                            }
                        }
                        .offset(x: offsetX, y: offsetY)
                    
                    // The PNG Bezel Image (with transparent screen and baked-in Dynamic Island)
                    if let imageName = style.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .shadow(color: Color.black.opacity(0.2), radius: w * 0.05, x: 0, y: w * 0.02)
                    }
                }
            }
            .aspectRatio(spec.imageAspect, contentMode: .fit)
        }
    }
}

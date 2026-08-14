import CoreGraphics
import Foundation

struct DeviceSpec: Equatable {
    let imageAspect: CGFloat // Aspect ratio of the mockup PNG
    let screenTopInsetRatio: CGFloat
    let screenBottomInsetRatio: CGFloat
    let screenLeftInsetRatio: CGFloat
    let screenRightInsetRatio: CGFloat
    
    let innerCornerRadiusRatio: CGFloat
    let islandWidthRatio: CGFloat
    let islandHeightRatio: CGFloat
    let islandTopInsetRatio: CGFloat
    
    // Proportions for the status bar
    let statusBarHeightRatio: CGFloat
    let statusBarElementTopInsetRatio: CGFloat
    
    static let generic = DeviceSpec(
        imageAspect: 1350.0 / 2760.0,
        screenTopInsetRatio: 69.0 / 2760.0,
        screenBottomInsetRatio: 69.0 / 2760.0,
        screenLeftInsetRatio: 72.0 / 1350.0,
        screenRightInsetRatio: 72.0 / 1350.0,
        innerCornerRadiusRatio: 0.12,
        islandWidthRatio: 0.3,
        islandHeightRatio: 0.08,
        islandTopInsetRatio: 0.03,
        statusBarHeightRatio: 0.08,
        statusBarElementTopInsetRatio: 0.045
    )
    
    static let iphone17 = DeviceSpec(
        imageAspect: 1350.0 / 2760.0,
        screenTopInsetRatio: 69.0 / 2760.0,
        screenBottomInsetRatio: 69.0 / 2760.0,
        screenLeftInsetRatio: 72.0 / 1350.0,
        screenRightInsetRatio: 72.0 / 1350.0,
        innerCornerRadiusRatio: 0.10,
        islandWidthRatio: 0.28,
        islandHeightRatio: 0.08,
        islandTopInsetRatio: 0.02,
        statusBarHeightRatio: 0.08,
        statusBarElementTopInsetRatio: 0.045
    )
    
    static let iphoneAir = DeviceSpec(
        imageAspect: 1380.0 / 2880.0,
        screenTopInsetRatio: 72.0 / 2880.0,
        screenBottomInsetRatio: 72.0 / 2880.0,
        screenLeftInsetRatio: 60.0 / 1380.0,
        screenRightInsetRatio: 60.0 / 1380.0,
        innerCornerRadiusRatio: 0.10,
        islandWidthRatio: 0.28,
        islandHeightRatio: 0.08,
        islandTopInsetRatio: 0.02,
        statusBarHeightRatio: 0.08,
        statusBarElementTopInsetRatio: 0.045
    )
}

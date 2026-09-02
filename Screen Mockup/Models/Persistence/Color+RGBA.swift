import SwiftUI

extension Color {
    init(rgba: ColorRGBA) {
        self.init(red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
    }
    
    var rgba: ColorRGBA {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorRGBA(r: Double(r), g: Double(g), b: Double(b), a: Double(a))
    }
}

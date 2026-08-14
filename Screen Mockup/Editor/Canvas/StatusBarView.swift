import SwiftUI

struct StatusBarView: View {
    let spec: DeviceSpec
    let isDarkContent: Bool
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let statusBarHeight = w * spec.statusBarHeightRatio
            
            HStack {
                // Time
                Text("9:41")
                    .font(.system(size: w * 0.04, weight: .semibold, design: .rounded))
                    .foregroundColor(isDarkContent ? .black : .white)
                    .padding(.leading, w * 0.10)
                
                Spacer()
                
                // Status Icons
                HStack(spacing: w * 0.015) {
                    Image(systemName: "cellularbars")
                        .font(.system(size: w * 0.035))
                    Image(systemName: "wifi")
                        .font(.system(size: w * 0.035))
                    Image(systemName: "battery.100")
                        .font(.system(size: w * 0.04))
                }
                .foregroundColor(isDarkContent ? .black : .white)
                .padding(.trailing, w * 0.10)
            }
            .frame(height: statusBarHeight)
        }
    }
}

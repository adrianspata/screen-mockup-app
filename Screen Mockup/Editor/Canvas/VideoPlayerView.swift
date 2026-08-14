import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: url)
        
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        player.isMuted = true // "utan ljud"
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // If the URL has changed, we create a new player and looper
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            let player = AVQueuePlayer()
            let item = AVPlayerItem(url: url)
            context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
            player.isMuted = true
            uiViewController.player = player
            player.play()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator {
        var looper: AVPlayerLooper?
        var currentURL: URL
        
        init(url: URL) {
            self.currentURL = url
        }
    }
}

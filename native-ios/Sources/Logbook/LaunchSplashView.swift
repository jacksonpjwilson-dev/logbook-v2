import AVFoundation
import SwiftUI

struct LaunchSplashView: View {
    var onComplete: () -> Void

    var body: some View {
        LaunchVideoSurface(onComplete: onComplete)
            .ignoresSafeArea()
            .accessibilityLabel("Logbook is opening")
            .task {
                // A missing, stalled or interrupted asset must never lock launch.
                try? await Task.sleep(for: .seconds(9))
                guard !Task.isCancelled else { return }
                onComplete()
            }
    }
}

private final class LaunchPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

private struct LaunchVideoSurface: UIViewRepresentable {
    let onComplete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIView(context: Context) -> LaunchPlayerView {
        let view = LaunchPlayerView()
        view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1)
        view.playerLayer.videoGravity = .resizeAspectFill
        guard let url = Bundle.main.url(forResource: "LogbookLaunch", withExtension: "mp4") else {
            DispatchQueue.main.async(execute: onComplete)
            return view
        }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        view.playerLayer.player = player
        context.coordinator.player = player
        context.coordinator.observe(item)
        player.play()
        return view
    }

    func updateUIView(_ uiView: LaunchPlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: LaunchPlayerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        uiView.playerLayer.player = nil
        coordinator.stopObserving()
    }

    final class Coordinator {
        var player: AVPlayer?
        private let onComplete: () -> Void
        private var tokens: [NSObjectProtocol] = []
        private var status: NSKeyValueObservation?

        init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }

        func observe(_ item: AVPlayerItem) {
            for name in [AVPlayerItem.didPlayToEndTimeNotification, AVPlayerItem.failedToPlayToEndTimeNotification] {
                tokens.append(NotificationCenter.default.addObserver(forName: name, object: item, queue: .main) { [weak self] _ in
                    self?.onComplete()
                })
            }
            status = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                if item.status == .failed {
                    DispatchQueue.main.async { self?.onComplete() }
                }
            }
        }

        func stopObserving() {
            tokens.forEach(NotificationCenter.default.removeObserver)
            tokens.removeAll()
            status = nil
        }

        deinit { stopObserving() }
    }
}

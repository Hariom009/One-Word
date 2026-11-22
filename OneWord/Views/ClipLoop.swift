//
//  ClipLoop.swift
//  OneWord
//
//  A word's context clip, looping silently behind its entry. Cats & Dogs is the
//  book that needs it: a bark on its own is a noise, and the two seconds of dog
//  that come with it are what make it a word.
//
//  THE CLIP CONTRACT — what `OneWord/Clips/<clip>.mp4` has to be:
//    • H.264 or HEVC in an .mp4, named exactly as the entry's `clip` field.
//    • NO audio track. The entry's `sound` recording is the sound; a clip that
//      carries its own would talk over it and duck the reader's music.
//    • 2–4 seconds, cut to loop: the last frame should sit next to the first
//      without a jump, since it runs on repeat for as long as the page is up.
//    • 720p on the long edge is plenty — it draws into a 200–320pt box. Shot
//      bigger, it costs bundle size and decode for pixels nobody sees.
//  Anything missing or unplayable simply doesn't draw; the entry falls back to
//  the layout it had before, so a half-shot book is never a broken one.
//

import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// One looping clip. It plays only while the page it is on is the page you are on —
/// a feed builds the cards either side of you, and three players running for two
/// cards you cannot see is three video decoders burning battery for nothing.
struct ClipLoop: View {
    let clip: String
    /// False for a card that is built but not shown; the clip holds its first frame.
    var playing = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ClipPlayer(url: Bundle.main.url(forResource: clip, withExtension: "mp4"),
                   playing: playing && !reduceMotion && !lowPower)
            // A fresh view per clip, so a page change loads the new file instead of
            // leaving the last word's dog looping under the new word.
            .id(clip)
            .accessibilityHidden(true)   // the entry's own text already says what this is
    }

    /// ponytail: read per body pass, not observed. Switching Low Power Mode on mid-loop
    /// leaves this clip running until the next redraw, which is a frame or two of video,
    /// not a battery problem worth a notification observer.
    private var lowPower: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }
}

#if os(macOS)
private typealias PlatformView = NSView
#else
private typealias PlatformView = UIView
#endif

/// Owns the player and keeps its layer the size of the view. A plain layer, not
/// AVKit's `VideoPlayer`: that one brings transport controls and a scrubber to
/// something that is meant to read as a moving picture, not a video to operate.
private final class LoopView: PlatformView {
    private let player = AVQueuePlayer()
    /// Held: the looper IS the loop, and letting it go stops the repeat.
    private var looper: AVPlayerLooper?
    private let playerLayer = AVPlayerLayer()

    init(url: URL?) {
        super.init(frame: .zero)
        #if os(macOS)
        wantsLayer = true
        layer = CALayer()
        #endif
        #if os(macOS)
        layer?.masksToBounds = true
        #else
        layer.masksToBounds = true
        #endif
        // Silent, always: see the clip contract above.
        player.isMuted = true
        // The file is in the bundle — there is no network to stall on, and waiting
        // for a buffer that is already there just delays the first frame.
        player.automaticallyWaitsToMinimizeStalling = false
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        // The video is a sublayer, and SwiftUI's `.clipShape` does not reliably mask
        // one — without this the frames paint past the view's bounds, square-cornered
        // and out over the gutter. Masking here means the clip is clipped wherever it
        // is used, rather than every call site having to remember to clip it.
        playerLayer.masksToBounds = true
        #if os(macOS)
        layer?.addSublayer(playerLayer)
        #else
        layer.addSublayer(playerLayer)
        #endif
        if let url { looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url)) }
    }

    required init?(coder: NSCoder) { fatalError("ClipLoop is never loaded from a nib") }

    func setPlaying(_ on: Bool) {
        // Asking a paused player to pause again is free; guarding it is not worth a branch.
        if on { player.play() } else { player.pause() }
    }

    #if os(macOS)
    override func layout() { super.layout(); resize() }
    #else
    override func layoutSubviews() { super.layoutSubviews(); resize() }
    #endif

    /// The layer sits outside the view's own layout, so without this it stays at zero
    /// and draws nothing. No implicit animation: a bounds change would otherwise
    /// cross-fade the video against itself on every rotation and resize.
    private func resize() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

private struct ClipPlayer {
    let url: URL?
    let playing: Bool

    func makeView() -> LoopView {
        let view = LoopView(url: url)
        view.setPlaying(playing)
        return view
    }

    func updateView(_ view: LoopView) { view.setPlaying(playing) }
}

#if os(macOS)
extension ClipPlayer: NSViewRepresentable {
    func makeNSView(context: Context) -> LoopView { makeView() }
    func updateNSView(_ view: LoopView, context: Context) { updateView(view) }
}
#else
extension ClipPlayer: UIViewRepresentable {
    func makeUIView(context: Context) -> LoopView { makeView() }
    func updateUIView(_ view: LoopView, context: Context) { updateView(view) }
}
#endif

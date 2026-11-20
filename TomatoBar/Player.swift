import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    private var workSound: AVAudioPlayer
    private var restSound: AVAudioPlayer
    private var postSound: AVAudioPlayer
    private var applauseSound: AVAudioPlayer

    @AppStorage("volume") var volume: Double = 1.0 {
        didSet {
            applyVolume()
        }
    }

    init() {
        workSound = TBPlayer.load("work")
        restSound = TBPlayer.load("rest")
        postSound = TBPlayer.load("post")
        applauseSound = TBPlayer.load("applause")
        applyVolume()
    }

    private static func load(_ name: String) -> AVAudioPlayer {
        guard let asset = NSDataAsset(name: name) else {
            fatalError("Missing sound asset: \(name)")
        }
        do {
            let player = try AVAudioPlayer(data: asset.data, fileTypeHint: AVFileType.wav.rawValue)
            player.prepareToPlay()
            return player
        } catch {
            fatalError("Error initializing player \(name): \(error)")
        }
    }

    private func applyVolume() {
        for sound in [workSound, restSound, postSound, applauseSound] {
            sound.setVolume(Float(volume), fadeDuration: 0)
        }
    }

    func play(_ kind: TBKind) {
        let sound: AVAudioPlayer
        switch kind {
        case .work: sound = workSound
        case .rest: sound = restSound
        case .post: sound = postSound
        }
        restart(sound)
    }

    func playApplause() {
        restart(applauseSound)
    }

    private func restart(_ sound: AVAudioPlayer) {
        sound.currentTime = 0
        sound.play()
    }
}

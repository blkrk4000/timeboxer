import AVFoundation
import SwiftUI

enum TBSound {
    /// Eigener, im Programm enthaltener Ton (bei "Ende": Gong)
    static let builtIn = "Timeboxer"
    /// Dateinamen in /System/Library/Sounds (in den Systemeinstellungen teils anders benannt, z. B. Glass = Crystal)
    static let system = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink",
    ]
}

/// Ereignisse, für die ein Ton gewählt werden kann
enum TBSlot: String, CaseIterable {
    case work, rest, post, end

    var label: String {
        switch self {
        case .work: return "Arbeit"
        case .rest: return "Pause"
        case .post: return "Nachbearbeitung"
        case .end: return "Ende"
        }
    }

    var assetName: String {
        switch self {
        case .work: return "work"
        case .rest: return "rest"
        case .post: return "post"
        case .end: return "gong"
        }
    }
}

class TBPlayer: ObservableObject {
    private var builtIn: [TBSlot: AVAudioPlayer] = [:]

    @AppStorage("soundWork") var soundWork = TBSound.builtIn
    @AppStorage("soundRest") var soundRest = TBSound.builtIn
    @AppStorage("soundPost") var soundPost = TBSound.builtIn
    @AppStorage("soundEnd") var soundEnd = TBSound.builtIn

    @AppStorage("volume") var volume: Double = 1.0 {
        didSet {
            for player in builtIn.values {
                player.setVolume(Float(volume), fadeDuration: 0)
            }
        }
    }

    init() {
        for slot in TBSlot.allCases {
            builtIn[slot] = TBPlayer.load(slot.assetName)
        }
        for player in builtIn.values {
            player.setVolume(Float(volume), fadeDuration: 0)
        }
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

    private func choice(for slot: TBSlot) -> String {
        switch slot {
        case .work: return soundWork
        case .rest: return soundRest
        case .post: return soundPost
        case .end: return soundEnd
        }
    }

    func play(_ slot: TBSlot) {
        let name = choice(for: slot)
        /* Systemton; fehlt er, spielt der eigene Ton, damit nie Stille herrscht */
        if name != TBSound.builtIn, let sound = NSSound(named: NSSound.Name(name)) {
            sound.stop()
            sound.volume = Float(volume)
            sound.play()
            return
        }
        guard let player = builtIn[slot] else {
            return
        }
        player.currentTime = 0
        player.play()
    }
}

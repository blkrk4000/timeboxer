import AVFoundation
import SwiftUI

struct TBBuiltInSound: Identifiable {
    let id: String
    let label: String
}

enum TBSound {
    /// Eigene, im Programm enthaltene Töne: id = Name des Assets
    static let builtIn = [
        TBBuiltInSound(id: "gong-tief", label: "Gong tief"),
        TBBuiltInSound(id: "gong-mittel", label: "Gong mittel"),
        TBBuiltInSound(id: "gong-hell", label: "Gong hell"),
        TBBuiltInSound(id: "klangschale", label: "Klangschale"),
        TBBuiltInSound(id: "aufstieg", label: "Aufstieg"),
        TBBuiltInSound(id: "abstieg", label: "Abstieg"),
        TBBuiltInSound(id: "doppelton", label: "Doppelton"),
    ]
    /// Dateinamen in /System/Library/Sounds (in den Systemeinstellungen teils anders benannt, z. B. Glass = Crystal)
    static let system = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink",
    ]
    /// Frühere Versionen speicherten "Timeboxer" als Auswahl; das wird auf den Standard des Ereignisses abgebildet.
    static let legacy = "Timeboxer"
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

    var defaultSound: String {
        switch self {
        case .work: return "gong-tief"
        case .rest: return "klangschale"
        case .post: return "gong-mittel"
        case .end: return "aufstieg"
        }
    }
}

class TBPlayer: ObservableObject {
    private var builtIn: [String: AVAudioPlayer] = [:]

    @AppStorage("soundWork") var soundWork = TBSlot.work.defaultSound
    @AppStorage("soundRest") var soundRest = TBSlot.rest.defaultSound
    @AppStorage("soundPost") var soundPost = TBSlot.post.defaultSound
    @AppStorage("soundEnd") var soundEnd = TBSlot.end.defaultSound

    @AppStorage("volume") var volume: Double = 1.0 {
        didSet {
            for player in builtIn.values {
                player.setVolume(Float(volume), fadeDuration: 0)
            }
        }
    }

    init() {
        for sound in TBSound.builtIn {
            builtIn[sound.id] = TBPlayer.load(sound.id)
        }
        for player in builtIn.values {
            player.setVolume(Float(volume), fadeDuration: 0)
        }
        for slot in TBSlot.allCases where choice(for: slot) == TBSound.legacy {
            set(slot.defaultSound, for: slot)
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

    private func set(_ value: String, for slot: TBSlot) {
        switch slot {
        case .work: soundWork = value
        case .rest: soundRest = value
        case .post: soundPost = value
        case .end: soundEnd = value
        }
    }

    func play(_ slot: TBSlot) {
        let name = choice(for: slot)
        if let player = builtIn[name] {
            restart(player)
        } else if let sound = NSSound(named: NSSound.Name(name)) {
            sound.stop()
            sound.volume = Float(volume)
            sound.play()
        } else if let player = builtIn[slot.defaultSound] {
            /* Systemton nicht gefunden: Standardton, damit nie Stille herrscht */
            restart(player)
        }
    }

    private func restart(_ player: AVAudioPlayer) {
        for other in builtIn.values where other.isPlaying && other !== player {
            other.stop()
        }
        player.currentTime = 0
        player.play()
    }
}

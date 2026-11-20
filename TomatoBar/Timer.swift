import KeyboardShortcuts
import SwiftUI

/// Abschnittstypen einer Timebox: A = Arbeit, P = Pause, N = Nachbearbeitung
enum TBKind: Character {
    case work = "A"
    case rest = "P"
    case post = "N"

    var title: String {
        switch self {
        case .work: return "Arbeit"
        case .rest: return "Pause"
        case .post: return "Nachbearbeitung"
        }
    }

    var slot: TBSlot {
        switch self {
        case .work: return .work
        case .rest: return .rest
        case .post: return .post
        }
    }

    var icon: NSImage.Name {
        switch self {
        case .work: return .work
        case .rest: return .shortRest
        case .post: return .longRest
        }
    }
}

struct TBSegment {
    let kind: TBKind
    let minutes: Int
}

enum TBSequence {
    /// "18A 5P 15A 5N" -> vier Abschnitte. Trenner: Leerzeichen, Komma, Plus, Minus.
    static func parse(_ text: String) -> [TBSegment]? {
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",+-"))
        let tokens = text.components(separatedBy: separators).filter { !$0.isEmpty }
        if tokens.isEmpty {
            return nil
        }
        var result = [TBSegment]()
        for token in tokens {
            guard let letter = token.uppercased().last,
                  let kind = TBKind(rawValue: letter),
                  let minutes = Int(String(token.dropLast())),
                  minutes > 0, minutes <= 240 else {
                return nil
            }
            result.append(TBSegment(kind: kind, minutes: minutes))
        }
        return result
    }
}

class TBTimer: ObservableObject {
    @AppStorage("sequence") var sequenceText = "15A 5P 15A 5N"
    @AppStorage("showTimerInMenuBar") var showTimerInMenuBar = true
    @AppStorage("hideIconWhileRunning") var hideIconWhileRunning = true

    public let player = TBPlayer()
    private var notificationCenter = TBNotificationCenter()
    private var segments: [TBSegment] = []
    private var index = 0
    private var finishTime = Date()
    private var timerFormatter = DateComponentsFormatter()
    @Published var timeLeftString: String = ""
    @Published var timer: DispatchSourceTimer?
    @Published var isPaused = false
    private var remainingWhenPaused: TimeInterval = 0
    private var currentIcon = NSImage.Name.idle

    /// Wird die Maschine im Ruhezustand nach Ablauf zu spät wach, bricht der Timer ab.
    private let overrunTimeLimit = -60.0

    init() {
        timerFormatter.unitsStyle = .positional
        timerFormatter.allowedUnits = [.minute, .second]
        timerFormatter.zeroFormattingBehavior = .pad

        KeyboardShortcuts.onKeyUp(for: .startStopTimer, action: startStop)

        let aem: NSAppleEventManager = NSAppleEventManager.shared()
        aem.setEventHandler(self,
                            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
                            forEventClass: AEEventClass(kInternetEventClass),
                            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                 withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.forKeyword(AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              scheme.caseInsensitiveCompare("timeboxer") == .orderedSame,
              let host = url.host else {
            print("url handling error: cannot parse url")
            return
        }
        switch host.lowercased() {
        case "startstop":
            startStop()
        case "skip":
            skip()
        case "pause":
            togglePause()
        default:
            print("url handling error: unknown command \(host)")
        }
    }

    // MARK: Steuerung

    func startStop() {
        if timer != nil {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard timer == nil, let parsed = TBSequence.parse(sequenceText) else {
            return
        }
        segments = parsed
        index = 0
        beginSegment()
    }

    func stop() {
        stopTicker()
        resetUI()
    }

    func togglePause() {
        guard timer != nil else {
            return
        }
        if isPaused {
            finishTime = Date().addingTimeInterval(remainingWhenPaused)
            isPaused = false
        } else {
            remainingWhenPaused = max(0, finishTime.timeIntervalSinceNow)
            isPaused = true
        }
        updateTimeLeft()
    }

    /// Springt zum nächsten Abschnitt (am letzten Abschnitt: beendet die Sequenz).
    func skip() {
        guard timer != nil else {
            return
        }
        advance()
    }

    // MARK: Ablauf

    private func beginSegment() {
        let segment = segments[index]
        finishTime = Date().addingTimeInterval(TimeInterval(segment.minutes * 60))
        currentIcon = segment.kind.icon
        isPaused = false
        player.play(segment.kind.slot)
        notificationCenter.send(
            title: segment.kind.title,
            body: "\(segment.minutes) min (\(index + 1)/\(segments.count))"
        )
        if timer == nil {
            startTicker()
        }
        updateTimeLeft()
    }

    private func advance() {
        index += 1
        if index < segments.count {
            beginSegment()
        } else {
            finish()
        }
    }

    private func finish() {
        stopTicker()
        resetUI()
        player.play(.end)
        notificationCenter.send(title: "Fertig", body: "Timebox abgeschlossen")
    }

    private func resetUI() {
        currentIcon = .idle
        isPaused = false
        updateTimeLeft()
    }

    // MARK: Ticker

    private func startTicker() {
        let queue = DispatchQueue(label: "Timer")
        let source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        source.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        source.setEventHandler { [weak self] in
            /* Cannot publish updates from background thread */
            DispatchQueue.main.async {
                self?.onTick()
            }
        }
        source.resume()
        timer = source
    }

    private func stopTicker() {
        timer?.cancel()
        timer = nil
    }

    private func onTick() {
        guard timer != nil, !isPaused else {
            return
        }
        let timeLeft = finishTime.timeIntervalSinceNow
        if timeLeft <= 0 {
            if timeLeft < overrunTimeLimit {
                stop()
            } else {
                advance()
            }
            return
        }
        updateTimeLeft()
    }

    func updateTimeLeft() {
        let running = timer != nil && index < segments.count
        /* Symbol nur ausblenden, wenn die Zeit stattdessen in der Menüleiste steht */
        let hideIcon = running && hideIconWhileRunning && showTimerInMenuBar
        TBStatusItem.shared.setIcon(name: hideIcon ? nil : currentIcon)
        guard running else {
            timeLeftString = ""
            TBStatusItem.shared.setTitle(title: nil)
            return
        }
        let end = isPaused ? Date().addingTimeInterval(remainingWhenPaused) : finishTime
        timeLeftString = timerFormatter.string(from: Date(), to: end) ?? ""
        if showTimerInMenuBar {
            let pause = isPaused ? "⏸ " : ""
            TBStatusItem.shared.setTitle(title: "\(pause)\(segments[index].kind.rawValue) \(timeLeftString)")
        } else {
            TBStatusItem.shared.setTitle(title: nil)
        }
    }
}

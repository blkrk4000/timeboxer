import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

extension KeyboardShortcuts.Name {
    static let startStopTimer = Self("startStopTimer")
}

private struct SoundRow: View {
    let slot: TBSlot
    @Binding var selection: String
    @EnvironmentObject var player: TBPlayer

    var body: some View {
        HStack {
            Text(slot.label)
            Spacer()
            Picker("", selection: $selection) {
                Text(slot == .end ? "Gong (Timeboxer)" : "Timeboxer").tag(TBSound.builtIn)
                ForEach(TBSound.system, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .labelsHidden()
            .frame(width: 180)
            .help("Ton für \"\(slot.label)\" – Auswahl wird zur Probe abgespielt")
            .onChange(of: selection) { _ in
                player.play(slot)
            }
        }
    }
}

private struct SoundsView: View {
    @EnvironmentObject var player: TBPlayer

    var body: some View {
        VStack(spacing: 4) {
            SoundRow(slot: .work, selection: $player.soundWork)
            SoundRow(slot: .rest, selection: $player.soundRest)
            SoundRow(slot: .post, selection: $player.soundPost)
            SoundRow(slot: .end, selection: $player.soundEnd)
            HStack {
                Text("Lautstärke")
                Slider(value: $player.volume, in: 0...1)
            }
        }
    }
}

struct TBPopoverView: View {
    @ObservedObject var timer = TBTimer()
    @ObservedObject private var launchAtLogin = LaunchAtLogin.observable
    @State private var buttonHovered = false

    private var segments: [TBSegment]? {
        TBSequence.parse(timer.sequenceText)
    }

    /// Eine feste Zeile unter dem Eingabefeld: Summe oder Fehlerhinweis (Höhe bleibt konstant).
    private var hint: Text {
        if let segments = segments {
            let total = segments.reduce(0) { $0 + $1.minutes }
            return Text("Gesamt: \(total) min · \(segments.count) Abschnitte")
                .foregroundColor(.secondary)
        }
        return Text("Ungültig – Beispiel: 18A 5P 15A 5N")
            .foregroundColor(.red)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                timer.startStop()
                TBStatusItem.shared.closePopover(nil)
            } label: {
                Text(timer.timer != nil ?
                     (buttonHovered ? "Stopp" : timer.timeLeftString) :
                        "Start")
                    /*
                      When appearance is set to "Dark" and accent color is set to "Graphite"
                      "defaultAction" button label's color is set to the same color as the
                      button, making the button look blank. #24
                     */
                    .foregroundColor(Color.white)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity)
            }
            .onHover { over in
                buttonHovered = over
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(timer.timer == nil && segments == nil)

            HStack {
                Button {
                    timer.togglePause()
                } label: {
                    Text(timer.isPaused ? "Fortsetzen" : "Pause")
                        .frame(maxWidth: .infinity)
                }
                .disabled(timer.timer == nil)
                Button {
                    timer.skip()
                } label: {
                    Text("Weiter")
                        .frame(maxWidth: .infinity)
                }
                .disabled(timer.timer == nil)
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A Arbeit · P Pause · N Nachbearbeitung")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    TextField("15A 5P 15A 5N", text: $timer.sequenceText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(timer.timer != nil)
                    hint.font(.caption)
                }
                .padding(4)
            }

            GroupBox {
                VStack {
                    KeyboardShortcuts.Recorder(for: .startStopTimer) {
                        Text("Tastenkürzel Start/Stopp")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .help("Globales Tastenkürzel zum Starten und Stoppen")
                    Toggle(isOn: $timer.showTimerInMenuBar) {
                        Text("Zeit in der Menüleiste")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.toggleStyle(.switch)
                        .help("Restzeit als Text neben dem Symbol anzeigen")
                        .onChange(of: timer.showTimerInMenuBar) { _ in
                            timer.updateTimeLeft()
                        }
                    Toggle(isOn: $timer.hideIconWhileRunning) {
                        Text("Symbol ausblenden beim Laufen")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.toggleStyle(.switch)
                        .help("Blendet das Tomaten-Symbol aus, solange der Timer läuft (spart Platz in der Menüleiste)")
                        .onChange(of: timer.hideIconWhileRunning) { _ in
                            timer.updateTimeLeft()
                        }
                    Toggle(isOn: $launchAtLogin.isEnabled) {
                        Text("Beim Anmelden starten")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.toggleStyle(.switch)
                }
                .padding(4)
            }

            GroupBox {
                SoundsView().environmentObject(timer.player)
                    .padding(4)
            }

            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Text("Über Timeboxer")
                    Spacer()
                    Text("⌘ A").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("a")
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text("Beenden")
                    Spacer()
                    Text("⌘ Q").foregroundColor(Color.gray)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
        }
        .padding(12)
    }
}

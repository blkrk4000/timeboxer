# Timeboxer

Menubar-Timer für macOS mit frei definierbaren Abschnitten (Timebox-Sequenzen).

Basis: [TomatoBar](https://github.com/ivoronin/TomatoBar) von Ilya Voronin (MIT).

## Sequenz

Eine Sequenz ist eine Liste aus `<Minuten><Typ>`:

| Typ | Bedeutung |
|---|---|
| A | Arbeit |
| P | Pause |
| N | Nachbearbeitung |

Beispiele: `15A 5P 15A 5N`, `18A 5P 15A 5N`, `40A 3N`. Trenner sind Leerzeichen, Komma, `+` oder `-`.

Pro Abschnitt gibt es einen eigenen Ton und eine Benachrichtigung am Anfang, am Ende der ganzen Sequenz einen Applaus.
Die Restzeit steht in der Menüleiste (`A 12:34`).

## Installation

1. Neueste `Timeboxer-v*.zip` unter [Releases](../../releases) laden und entpacken.
2. `Timeboxer.app` nach `/Programme` verschieben.
3. Einmalig Quarantäne entfernen (App ist nicht notarisiert):
   `xattr -r -d com.apple.quarantine /Applications/Timeboxer.app`

## URL-Schema

`open timeboxer://startstop`, `timeboxer://pause` und `timeboxer://skip` (z. B. für Keyboard Maestro).

## Lizenz

MIT, siehe `LICENSE`.

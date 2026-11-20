# Timeboxer

Menubar-Timer für macOS mit frei definierbaren Abschnitten (Timebox-Sequenzen).

Entstanden für die Arbeitseinheiten (AE) nach Anna Höcker, „Heute fange ich wirklich an!“ (Timeboxing mit Arbeit, Pause und Nachbearbeitung).

Basis: [TomatoBar](https://github.com/ivoronin/TomatoBar) von Ilya Voronin (MIT).

Entwickelt mit [Claude](https://claude.ai) (Anthropic): Code, Build-Workflow und die eingebauten, synthetisch erzeugten Töne.

## Sequenz

Eine Sequenz ist eine Liste aus `<Minuten><Typ>`:

| Typ | Bedeutung |
|---|---|
| A | Arbeit |
| P | Pause |
| N | Nachbearbeitung |

Beispiele: `15A 5P 15A 5N`, `18A 5P 15A 5N`, `40A 3N`. Trenner sind Leerzeichen, Komma, `+` oder `-`.

Jeder Abschnitt dauert 1 bis 240 Minuten, die Anzahl der Abschnitte ist nicht begrenzt.

Am Anfang jedes Abschnitts gibt es einen Ton und eine Benachrichtigung, am Ende der ganzen Sequenz einen Schlusston.
Die Restzeit steht in der Menüleiste (`A 12:34`).

## Töne

Je Ereignis frei wählbar: sieben eingebaute Töne (Gong tief, Gong mittel, Gong hell, Klangschale, Aufstieg, Abstieg, Doppelton) oder die macOS-Systemtöne.

| Ereignis | Standard |
|---|---|
| Arbeit | Gong tief |
| Pause | Klangschale |
| Nachbearbeitung | Gong mittel |
| Ende | Aufstieg |

## Installation

1. Neueste `Timeboxer-v*.zip` unter [Releases](../../releases) laden und entpacken.
2. `Timeboxer.app` nach `/Programme` verschieben.
3. Einmalig Quarantäne entfernen (App ist nicht notarisiert):
   `xattr -r -d com.apple.quarantine /Applications/Timeboxer.app`

## URL-Schema

`open timeboxer://startstop`, `timeboxer://pause` und `timeboxer://skip` (z. B. für Keyboard Maestro).

## Lizenz

MIT, siehe `LICENSE`.

# Antigravity Voice Reader (Text-to-Speech)

<p align="center">
  <strong>Language:</strong>
  <a href="README.md">Español</a> |
  <a href="README.en.md">English</a> |
  <a href="README.de.md">Deutsch</a>
</p>

Ein leichtgewichtiger schwebender Text-to-Speech-Player, der Antworten des Antigravity IDE-Agenten auf natürliche Weise über die native Windows-Sprachausgabe vorliest.

## Hauptfunktionen

*   **Intelligente Mehrsprachigkeit (Auto-Erkennung):** Analysiert den Antworttext in Echtzeit und wechselt automatisch zwischen den installierten Windows-Stimmen:
    *   🇩🇪 **Deutsch (de-DE):** `Microsoft Hedda Desktop` (perfekte Aussprache von Umlauten ä, ö, ü, ß).
    *   🇪🇸 **Spanisch (es-ES):** `Microsoft Helena Desktop`.
    *   🇺🇸 **Englisch (en-US):** `Microsoft Zira Desktop`.
*   **Manuelle Sprachauswahl:** Im erweiterten Modus steht ein Dropdown-Menü zur Verfügung, um die Sprache festzulegen (`Auto`, `Español`, `Deutsch`, `English`).
*   **Kontextbezogene Textbereinigung:** Entfernt Codeblöcke und Links sprachspezifisch (*"Code ausgelassen"* im Deutschen vs. *"código omitido"* im Spanischen).
*   **0-Block UI (Hohe Leistung):** Nutzt einen StreamReader auf Byte-Ebene auf `transcript.jsonl` für minimale RAM-Nutzung und verzögerungsfreie GUI-Bedienung.
*   **Hybrider Player:** Schwebendes Fenster (`TopMost`) mit kompaktem Minimodus und erweitertem Modus mit Live-Textanzeige.

## Systemanforderungen
- Windows 10 oder Windows 11.
- PowerShell.
- Antigravity IDE installiert.

## Funktionsweise
Das Skript überwacht in Echtzeit die Chat-Protokolldatei (`transcript.jsonl`). Sobald eine neue Antwort des Assistenten ("MODEL") vorliegt, erkennt es die Sprache, bereinigt den Text und übergibt ihn asynchron an die Sprachausgabe (`SpeakAsync`).

## Installation und Verwendung

Der einfachste Weg zur Ausführung sind die beiliegenden `.bat`-Dateien:

0. **Schnellinstallation (Desktop-Verknüpfung):**
   Doppelklick auf **`Instalar_Acceso.bat`**. Dies erstellt automatisch eine Verknüpfung auf dem Desktop.

1. **Täglicher Gebrauch (Empfohlen - Auto-Erkennung):**
   Doppelklick auf **`Lector.bat`** (oder die Desktop-Verknüpfung). Koppelt sich automatisch an den aktuellen Chat und erkennt die Sprache pro Nachricht.

2. **Direkt auf Deutsch starten:**
   Doppelklick auf **`Lector_DE.bat`**. Startet direkt auf Deutsch mit der Begrüßung *"Sprachausgabe bereit"*.

3. **Befehlszeilenmodus (Erweitert):**
   ```powershell
   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File .\reader_gui.ps1 -ConversationId auto -Language auto
   ```

## Player-Steuerung (Kompakt & Erweitert)
- ⏯️ **Pause / Resume:** Pausiert die Wiedergabe und setzt sie an gleicher Stelle fort.
- ⏹️ **Stop:** Stoppt die aktuelle Sprachausgabe sofort.
- 🔄 **Repeat:** Liest die aktuelle Nachricht erneut von vorne vor.
- 🔃 **Reload:** Synchronisiert erneut mit dem neuesten aktiven Chat im IDE und liest sofort die letzte Antwort vor.
- 🗖 **Maximieren / Erweiterter Modus:** Vergrößert das Fenster, um die Live-Transkription, den Status und das Sprachmenü anzuzeigen.
- 🗗 **Kompaktmodus:** Stellt die Mini-Leiste über die Wiederherstellen-Schaltfläche oder den Button `Compact` wieder her.
- 🗕 **Minimieren:** Minimiert das Fenster in die Windows-Taskleiste.
- ❌ **Schließen:** Beendet die Anwendung.

### Zusätzliche Hinweise
- Codeblöcke mit dreifachen Backticks und URLs werden automatisch übersprungen.
- Zwischen Kompakt- und Großansicht kann jederzeit unterbrechungsfrei gewechselt werden.

<br>
<p align="center">
  <a href="./Project.md"><img src="https://img.shields.io/badge/Architektur-Project.md-blue?style=for-the-badge"></a>
</p>

---
<br>
<p align="center">
  <small>All rights reserved © 2026 | <a href="https://github.com/dwn10">Darwin Paz</a></small>
</p>

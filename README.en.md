# Antigravity Voice Reader (Text-to-Speech)

<p align="center">
  <strong>Language:</strong>
  <a href="README.md">Español</a> |
  <a href="README.en.md">English</a> |
  <a href="README.de.md">Deutsch</a>
</p>

A lightweight floating text-to-speech player designed to read aloud AI agent responses in Antigravity IDE naturally using native Windows TTS engines.

## Key Features

*   **Intelligent Multilingual Support (Auto-Detection):** Analyzes response text in real-time and automatically switches between installed Windows voices:
    *   🇩🇪 **German (de-DE):** `Microsoft Hedda Desktop` (pronounces umlauts ä, ö, ü, ß natively).
    *   🇪🇸 **Spanish (es-ES):** `Microsoft Helena Desktop`.
    *   🇺🇸 **English (en-US):** `Microsoft Zira Desktop`.
*   **Manual Language Selector:** In expanded mode, a dropdown allows locking the reader to a specific language (`Auto`, `Español`, `Deutsch`, `English`).
*   **Contextual Text Cleaning:** Strips code blocks and links, adapting announcements to the target language (e.g., *"code omitted"* vs *"Code ausgelassen"* vs *"código omitido"*).
*   **0-Block UI (High Performance):** Uses byte-level StreamReader tracking on `transcript.jsonl` with minimal memory usage and zero UI freezing.
*   **Hybrid Player GUI:** Floating `TopMost` interface with a compact mini mode and an expanded mode with live response transcription.

## Requirements
- Windows 10 or Windows 11.
- PowerShell.
- Antigravity IDE installed.

## How It Works
The script continuously monitors the internal chat log (`transcript.jsonl`). When it detects a new message from the agent ("MODEL"), it detects the language, normalizes the text, and routes it to the speech synthesizer asynchronously (`SpeakAsync`).

## Installation & Usage

The easiest way to run the tool is via the included batch files:

0. **Quick Setup (Desktop Shortcut):**
   Double-click **`Instalar_Acceso.bat`**. This creates an `"Antigravity Voice Reader"` shortcut on your Desktop.

1. **Daily Use (Recommended - Auto-Detection):**
   Double-click **`Lector.bat`** (or your desktop shortcut). It automatically attaches to your active chat and detects language per message.

2. **Launch Directly in German Mode:**
   Double-click **`Lector_DE.bat`**. Launches the reader preset to German with the greeting *"Sprachausgabe bereit"*.

3. **Command Line Mode (Advanced):**
   Launch manually with parameters:
   ```powershell
   powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File .\reader_gui.ps1 -ConversationId auto -Language auto
   ```

## Player Controls (Compact & Expanded)
- ⏯️ **Pause / Resume:** Pauses playback and resumes from the exact position.
- ⏹️ **Stop:** Immediately stops speech playback.
- 🔄 **Repeat:** Replays the current message from the beginning.
- 🔃 **Reload:** Re-syncs with the latest active chat in the IDE and immediately reads the latest response.
- 🗖 **Maximize / Expanded Mode:** Expands the window to display the live text transcription, status indicator, and language selector.
- 🗗 **Compact Mode:** Restores the player back to the floating mini toolbar via the window restore button or the `Compact` button.
- 🗕 **Minimize:** Minimizes the window to the Windows taskbar.
- ❌ **Close:** Terminates the reader application.

### Additional Notes
- Triple-backtick code blocks and URLs are automatically omitted to avoid listening to raw code and symbols.
- You can freely switch between compact and expanded views at any time without interrupting speech playback.

<br>
<p align="center">
  <a href="./Project.md"><img src="https://img.shields.io/badge/Architecture-Project.md-blue?style=for-the-badge"></a>
</p>

---
<br>
<p align="center">
  <small>All rights reserved © 2026 | <a href="https://github.com/dwn10">Darwin Paz</a></small>
</p>

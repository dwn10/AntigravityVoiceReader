param(
    [string]$ConversationId = "auto"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Speech

# Buscar última conversación si es auto
if ($ConversationId -eq "auto") {
    $brainPath = "$env:USERPROFILE\.gemini\antigravity-ide\brain"
    # Buscar directamente el transcript.jsonl que fue modificado hace menos tiempo
    $latestTranscript = Get-ChildItem -Path $brainPath -Filter "transcript.jsonl" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestTranscript) {
        $transcriptPath = $latestTranscript.FullName
    } else {
        $transcriptPath = ""
    }
} else {
    $transcriptPath = "$env:USERPROFILE\.gemini\antigravity-ide\brain\$ConversationId\.system_generated\logs\transcript.jsonl"
}

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$esVoice = $synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -like "es-*" } | Select-Object -First 1
if ($esVoice) { try { $synth.SelectVoice($esVoice.VoiceInfo.Name) } catch {} }

# Configuración de la Interfaz (Form)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Voz"
$form.Size = New-Object System.Drawing.Size(190, 80)
$form.TopMost = $true
$form.FormBorderStyle = 'FixedToolWindow'
$form.StartPosition = 'CenterScreen'
# Hemos removido la asignación manual de Location para evitar el error.

# Botones
$btnPlayPause = New-Object System.Windows.Forms.Button
$btnPlayPause.Location = New-Object System.Drawing.Point(5, 5)
$btnPlayPause.Size = New-Object System.Drawing.Size(50, 30)
$btnPlayPause.Text = "Pausa"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(60, 5)
$btnStop.Size = New-Object System.Drawing.Size(50, 30)
$btnStop.Text = "Stop"

$btnReplay = New-Object System.Windows.Forms.Button
$btnReplay.Location = New-Object System.Drawing.Point(115, 5)
$btnReplay.Size = New-Object System.Drawing.Size(50, 30)
$btnReplay.Text = "Repetir"

$form.Controls.Add($btnPlayPause)
$form.Controls.Add($btnStop)
$form.Controls.Add($btnReplay)

$global:lastText = ""
$global:lastFilePos = 0

if (Test-Path $transcriptPath) {
    $fileInfo = New-Object System.IO.FileInfo($transcriptPath)
    $global:lastFilePos = $fileInfo.Length
}

# Eventos de los botones
$btnPlayPause.Add_Click({
    if ($synth.State -eq 'Paused') {
        $synth.Resume()
    } elseif ($synth.State -eq 'Speaking') {
        $synth.Pause()
    }
})

$btnStop.Add_Click({
    $synth.SpeakAsyncCancelAll()
})

$btnReplay.Add_Click({
    $synth.SpeakAsyncCancelAll()
    if ($global:lastText -ne "") {
        $synth.SpeakAsync($global:lastText) | Out-Null
    }
})

# Lógica del Timer (lee asíncronamente el archivo sin bloquear botones)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    if (Test-Path $transcriptPath) {
        $fileInfo = New-Object System.IO.FileInfo($transcriptPath)
        if ($fileInfo.Length -gt $global:lastFilePos) {
            $stream = $fileInfo.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $stream.Position = $global:lastFilePos
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
            $newContent = $reader.ReadToEnd()
            $global:lastFilePos = $stream.Position
            $reader.Close()
            $stream.Close()
            
            $newLines = $newContent -split "`n"
            foreach ($line in $newLines) {
                if ($line -match '"source":"MODEL"' -and $line -match '"type":"PLANNER_RESPONSE"') {
                    try {
                        $json = $line | ConvertFrom-Json
                        if ($json.content) {
                            $text = $json.content -replace '<[^>]+>', ''
                            $text = $text -replace '(?s)```.*?```', ' código omitido '
                            $text = $text -replace '\*\*|\*|__|_|~', ''
                            $text = $text -replace '#', ''
                            $text = $text -replace '\[(.*?)\]\(.*?\)', '$1'
                            $text = $text -replace 'http[s]?://\S+', ' un enlace '
                            $text = $text.Replace("!", "").Replace("?", "")
                            $text = $text.Replace("$([char]161)", "").Replace("$([char]191)", "")
                            $text = [System.Text.RegularExpressions.Regex]::Replace($text, '[\uD83C-\uDBFF\uDC00-\uDFFF]+', '')
                            
                            # Quitar tildes y eñes usando los valores numéricos exactos
                            $text = $text.Replace("$([char]241)", "ni").Replace("$([char]209)", "Ni")
                            $text = $text.Replace("$([char]225)", "a").Replace("$([char]233)", "e").Replace("$([char]237)", "i").Replace("$([char]243)", "o").Replace("$([char]250)", "u")
                            $text = $text.Replace("$([char]193)", "A").Replace("$([char]201)", "E").Replace("$([char]205)", "I").Replace("$([char]211)", "O").Replace("$([char]218)", "U")
                            
                            $global:lastText = $text
                            $synth.SpeakAsync($text) | Out-Null
                        }
                    } catch {}
                }
            }
        }
    }
})

$form.Add_FormClosed({
    $timer.Stop()
    $synth.Dispose()
})

$timer.Start()
$synth.SpeakAsync("Interfaz iniciada") | Out-Null
[System.Windows.Forms.Application]::Run($form)

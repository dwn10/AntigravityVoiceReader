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
    }
    else {
        $transcriptPath = ""
    }
}
else {
    $transcriptPath = "$env:USERPROFILE\.gemini\antigravity-ide\brain\$ConversationId\.system_generated\logs\transcript.jsonl"
}

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$esVoice = $synth.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -like "es-*" } | Select-Object -First 1
if ($esVoice) { try { $synth.SelectVoice($esVoice.VoiceInfo.Name) } catch {} }

# Configuración de la Interfaz (Form)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Voice Reader"
$compactSize = New-Object System.Drawing.Size(280, 85)
$form.Size = $compactSize
$form.MinimumSize = New-Object System.Drawing.Size(260, 85)
$form.TopMost = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.MaximizeBox = $true
$form.MinimizeBox = $true
$form.ShowInTaskbar = $true
$form.StartPosition = 'CenterScreen'

# Panel superior para controles
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$topPanel.Height = 44
$form.Controls.Add($topPanel)

# Botones en inglés
$btnPlayPause = New-Object System.Windows.Forms.Button
$btnPlayPause.Location = New-Object System.Drawing.Point(8, 7)
$btnPlayPause.Size = New-Object System.Drawing.Size(65, 30)
$btnPlayPause.Text = "Pause"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(78, 7)
$btnStop.Size = New-Object System.Drawing.Size(60, 30)
$btnStop.Text = "Stop"

$btnReplay = New-Object System.Windows.Forms.Button
$btnReplay.Location = New-Object System.Drawing.Point(143, 7)
$btnReplay.Size = New-Object System.Drawing.Size(65, 30)
$btnReplay.Text = "Repeat"

$btnCompact = New-Object System.Windows.Forms.Button
$btnCompact.Location = New-Object System.Drawing.Point(214, 7)
$btnCompact.Size = New-Object System.Drawing.Size(95, 30)
$btnCompact.Text = "Compact"
$btnCompact.Visible = $false

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(318, 14)
$lblStatus.AutoSize = $true
$lblStatus.Text = "Status: Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.Visible = $false

$topPanel.Controls.AddRange(@($btnPlayPause, $btnStop, $btnReplay, $btnCompact, $lblStatus))

# Área de texto expandida (visible al maximizar o ampliar)
$txtSpeech = New-Object System.Windows.Forms.TextBox
$txtSpeech.Multiline = $true
$txtSpeech.ReadOnly = $true
$txtSpeech.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtSpeech.Dock = [System.Windows.Forms.DockStyle]::Fill
$txtSpeech.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$txtSpeech.Visible = $false
$form.Controls.Add($txtSpeech)
$txtSpeech.BringToFront()

# Evento para volver al modo compacto
$btnCompact.Add_Click({
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.Size = $compactSize
})

# Manejo dinámico al maximizar o restaurar a modo compacto
$form.Add_Resize({
    if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Maximized -or $form.Height -gt 130) {
        $btnCompact.Visible = $true
        $lblStatus.Visible = $true
        $txtSpeech.Visible = $true
    }
    else {
        $btnCompact.Visible = $false
        $lblStatus.Visible = $false
        $txtSpeech.Visible = $false
    }
})

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
            $btnPlayPause.Text = "Pause"
            $lblStatus.Text = "Status: Reading..."
        }
        elseif ($synth.State -eq 'Speaking') {
            $synth.Pause()
            $btnPlayPause.Text = "Resume"
            $lblStatus.Text = "Status: Paused"
        }
    })

$btnStop.Add_Click({
        $synth.SpeakAsyncCancelAll()
        $btnPlayPause.Text = "Pause"
        $lblStatus.Text = "Status: Stopped"
    })

$btnReplay.Add_Click({
        try {
            $synth.SpeakAsyncCancelAll()
            [System.Threading.Thread]::Sleep(50)
            if ($global:lastText -ne "") {
                $synth.SpeakAsync($global:lastText) | Out-Null
                $btnPlayPause.Text = "Pause"
                $lblStatus.Text = "Status: Reading..."
            }
        }
        catch {}
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
                                $txtSpeech.Text = $text
                                $lblStatus.Text = "Status: Reading..."
                                $btnPlayPause.Text = "Pause"
                                $synth.SpeakAsync($text) | Out-Null
                            }
                        }
                        catch {}
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

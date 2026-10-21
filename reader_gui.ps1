param(
    [string]$ConversationId = "auto",
    [string]$Language = "auto"
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

# Inicializar sintetizador y mapear voces instaladas (Español, Alemán, Inglés)
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$installedVoices = $synth.GetInstalledVoices()
$voiceMap = @{}

$deVoice = $installedVoices | Where-Object { $_.VoiceInfo.Culture.Name -like "de-*" } | Select-Object -First 1
$esVoice = $installedVoices | Where-Object { $_.VoiceInfo.Culture.Name -like "es-*" } | Select-Object -First 1
$enVoice = $installedVoices | Where-Object { $_.VoiceInfo.Culture.Name -like "en-*" } | Select-Object -First 1

if ($deVoice) { $voiceMap['de'] = $deVoice.VoiceInfo.Name }
if ($esVoice) { $voiceMap['es'] = $esVoice.VoiceInfo.Name }
if ($enVoice) { $voiceMap['en'] = $enVoice.VoiceInfo.Name }

# Función de detección inteligente de idioma (Basada en ponderación estadística)
function Detect-Language([string]$raw) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return "es" }

    $scoreDe = 0
    $scoreEs = 0
    $scoreEn = 0

    # Ponderadores por caracteres unívocos
    # ß (Eszett) es 100% exclusivo del alemán
    if ($raw -match "$([char]223)") { $scoreDe += 3 }

    # Caracteres 100% exclusivos del español (ñ, Ñ, ¿, ¡)
    if ($raw -match "[$([char]241)$([char]209)$([char]191)$([char]161)]") { $scoreEs += 3 }

    # Análisis de frecuencias léxicas y palabras funcionales (Stopwords)
    $words = [System.Text.RegularExpressions.Regex]::Matches($raw.ToLower(), '\b[a-z]{2,8}\b') | ForEach-Object { $_.Value }

    $swDe = [System.Collections.Generic.HashSet[string]]@('der','die','das','und','ist','nicht','fuer','mit','sich','dem','dass','werden','sind','ein','eine','einen','einer','wurde','haben','nach','wie','bei','oder','aber','wird','kann','noch','wenn','durch','gibt','auch','bitte','hallo','danke','jetzt','sehr','hier','fuer')
    $swEs = [System.Collections.Generic.HashSet[string]]@('el','la','los','las','en','que','de','es','por','con','para','una','uno','del','al','se','como','pero','su','este','esta','esto','son','fue','tiene','hay','todo','todos','sobre','cuando','muy','donde','desde','sin','hola','gracias','si','te','ya','no','nada','ahora','tambien','mas')
    $swEn = [System.Collections.Generic.HashSet[string]]@('the','and','to','of','in','for','is','on','that','with','as','this','are','from','at','by','be','we','an','have','can','which','you','was','not','but','all','your','when','how','what','with')

    foreach ($w in $words) {
        if ($swDe.Contains($w)) { $scoreDe++ }
        if ($swEs.Contains($w)) { $scoreEs++ }
        if ($swEn.Contains($w)) { $scoreEn++ }
    }

    # Si hay clara mayoría de palabras en alemán
    if ($scoreDe -gt $scoreEs -and $scoreDe -gt $scoreEn) { return "de" }
    # Si hay clara mayoría de palabras en inglés
    if ($scoreEn -gt $scoreEs -and $scoreEn -gt $scoreDe) { return "en" }
    # Por defecto español ante empates o textos en español
    return "es"
}

# Normalización de texto según el idioma destino
function Normalize-Text([string]$content, [string]$lang) {
    $text = $content -replace '<[^>]+>', ''
    
    if ($lang -eq 'de') {
        $text = $text -replace '(?s)```.*?```', ' Code ausgelassen '
        $text = $text -replace 'http[s]?://\S+', ' ein Link '
    }
    elseif ($lang -eq 'en') {
        $text = $text -replace '(?s)```.*?```', ' code omitted '
        $text = $text -replace 'http[s]?://\S+', ' a link '
    }
    else {
        $text = $text -replace '(?s)```.*?```', ' código omitido '
        $text = $text -replace 'http[s]?://\S+', ' un enlace '
    }

    $text = $text -replace '\*\*|\*|__|_|~', ''
    $text = $text -replace '#', ''
    $text = $text -replace '\[(.*?)\]\(.*?\)', '$1'
    $text = $text.Replace("!", "").Replace("?", "")
    $text = $text.Replace("$([char]161)", "").Replace("$([char]191)", "")
    $text = [System.Text.RegularExpressions.Regex]::Replace($text, '[\uD83C-\uDBFF\uDC00-\uDFFF]+', '')

    if ($lang -eq 'es') {
        $text = $text.Replace("$([char]241)", "ni").Replace("$([char]209)", "Ni")
        $text = $text.Replace("$([char]225)", "a").Replace("$([char]233)", "e").Replace("$([char]237)", "i").Replace("$([char]243)", "o").Replace("$([char]250)", "u")
        $text = $text.Replace("$([char]193)", "A").Replace("$([char]201)", "E").Replace("$([char]205)", "I").Replace("$([char]211)", "O").Replace("$([char]218)", "U")
    }

    return $text
}

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
$btnCompact.Size = New-Object System.Drawing.Size(75, 30)
$btnCompact.Text = "Compact"
$btnCompact.Visible = $false

# Selector de Idioma (visible en modo expandido)
$cmbLang = New-Object System.Windows.Forms.ComboBox
$cmbLang.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLang.Location = New-Object System.Drawing.Point(295, 10)
$cmbLang.Size = New-Object System.Drawing.Size(125, 25)
$cmbLang.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$cmbLang.Items.AddRange(@('Auto (Detect)', 'Español (ES)', 'Deutsch (DE)', 'English (EN)'))
$cmbLang.Visible = $false

# Establecer selección inicial según parámetro
switch ($Language.ToLower()) {
    "de" { $cmbLang.SelectedIndex = 2 }
    "es" { $cmbLang.SelectedIndex = 1 }
    "en" { $cmbLang.SelectedIndex = 3 }
    default { $cmbLang.SelectedIndex = 0 }
}

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(430, 14)
$lblStatus.AutoSize = $true
$lblStatus.Text = "Status: Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.Visible = $false

$topPanel.Controls.AddRange(@($btnPlayPause, $btnStop, $btnReplay, $btnCompact, $cmbLang, $lblStatus))

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
        $cmbLang.Visible = $true
        $lblStatus.Visible = $true
        $txtSpeech.Visible = $true
    }
    else {
        $btnCompact.Visible = $false
        $cmbLang.Visible = $false
        $lblStatus.Visible = $false
        $txtSpeech.Visible = $false
    }
})

# Evento al cambiar idioma manualmente
$cmbLang.Add_SelectedIndexChanged({
    switch ($cmbLang.SelectedIndex) {
        1 { if ($voiceMap['es']) { try { $synth.SelectVoice($voiceMap['es']) } catch {} } }
        2 { if ($voiceMap['de']) { try { $synth.SelectVoice($voiceMap['de']) } catch {} } }
        3 { if ($voiceMap['en']) { try { $synth.SelectVoice($voiceMap['en']) } catch {} } }
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
                                # Determinar idioma según selector o detección automática
                                $targetLang = "es"
                                switch ($cmbLang.SelectedIndex) {
                                    1 { $targetLang = "es" }
                                    2 { $targetLang = "de" }
                                    3 { $targetLang = "en" }
                                    default { $targetLang = Detect-Language $json.content }
                                }

                                # Conmutar voz correspondiente si está disponible
                                if ($voiceMap[$targetLang]) {
                                    try { $synth.SelectVoice($voiceMap[$targetLang]) } catch {}
                                }

                                $flag = switch ($targetLang) {
                                    "de" { "[DE]" }
                                    "en" { "[EN]" }
                                    default { "[ES]" }
                                }

                                $text = Normalize-Text $json.content $targetLang

                                $global:lastText = $text
                                $txtSpeech.Text = $text
                                $lblStatus.Text = "Status: Reading $flag"
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

# Saludo inicial según idioma configurado
if ($cmbLang.SelectedIndex -eq 2) {
    if ($voiceMap['de']) { try { $synth.SelectVoice($voiceMap['de']) } catch {} }
    $synth.SpeakAsync("Sprachausgabe bereit") | Out-Null
}
else {
    if ($voiceMap['es']) { try { $synth.SelectVoice($voiceMap['es']) } catch {} }
    $synth.SpeakAsync("Interfaz iniciada") | Out-Null
}

[System.Windows.Forms.Application]::Run($form)

param(
    [string]$ConversationId = "auto",
    [string]$Language = "auto"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Speech

# Función de búsqueda rápida de la conversación más reciente (evita escaneo recursivo lento)
function Get-LatestTranscriptPath {
    $brainPath = "$env:USERPROFILE\.gemini\antigravity-ide\brain"
    if (-not (Test-Path $brainPath)) { return "" }
    
    $candidate = Get-ChildItem -Path $brainPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "tempmediaStorage" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 10 |
        ForEach-Object { Join-Path $_.FullName ".system_generated\logs\transcript.jsonl" } |
        Where-Object { Test-Path $_ } |
        Get-Item |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($candidate) {
        return $candidate.FullName
    }
    return ""
}

# Resolver ruta inicial de la transcripción
if ($ConversationId -eq "auto") {
    $global:transcriptPath = Get-LatestTranscriptPath
}
else {
    $global:transcriptPath = "$env:USERPROFILE\.gemini\antigravity-ide\brain\$ConversationId\.system_generated\logs\transcript.jsonl"
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
$compactSize = New-Object System.Drawing.Size(296, 85)
$form.Size = $compactSize
$form.MinimumSize = New-Object System.Drawing.Size(275, 85)
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
$btnPlayPause.Size = New-Object System.Drawing.Size(60, 30)
$btnPlayPause.Text = "Pause"

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Location = New-Object System.Drawing.Point(72, 7)
$btnStop.Size = New-Object System.Drawing.Size(52, 30)
$btnStop.Text = "Stop"

$btnReplay = New-Object System.Windows.Forms.Button
$btnReplay.Location = New-Object System.Drawing.Point(128, 7)
$btnReplay.Size = New-Object System.Drawing.Size(62, 30)
$btnReplay.Text = "Repeat"

$btnReload = New-Object System.Windows.Forms.Button
$btnReload.Location = New-Object System.Drawing.Point(194, 7)
$btnReload.Size = New-Object System.Drawing.Size(62, 30)
$btnReload.Text = "Reload"

$btnCompact = New-Object System.Windows.Forms.Button
$btnCompact.Location = New-Object System.Drawing.Point(262, 7)
$btnCompact.Size = New-Object System.Drawing.Size(72, 30)
$btnCompact.Text = "Compact"
$btnCompact.Visible = $false

# Selector de Idioma (visible en modo expandido)
$cmbLang = New-Object System.Windows.Forms.ComboBox
$cmbLang.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmbLang.Location = New-Object System.Drawing.Point(342, 10)
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
$lblStatus.Location = New-Object System.Drawing.Point(475, 14)
$lblStatus.AutoSize = $true
$lblStatus.Text = "Status: Ready"
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblStatus.Visible = $false

$topPanel.Controls.AddRange(@($btnPlayPause, $btnStop, $btnReplay, $btnReload, $btnCompact, $cmbLang, $lblStatus))

# Tooltips informativos para cada control
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($btnPlayPause, "Pause or resume reading")
$toolTip.SetToolTip($btnStop, "Stop reading")
$toolTip.SetToolTip($btnReplay, "Repeat current speech")
$toolTip.SetToolTip($btnReload, "Reload: Fetch and read latest response from active chat")
$toolTip.SetToolTip($btnCompact, "Return to compact view")

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
$global:autoCheckCounter = 0

# Función para sincronizar y leer la última respuesta del chat activo
function Update-LatestSpeech([bool]$speakImmediately = $true) {
    if ($ConversationId -eq "auto") {
        $latest = Get-LatestTranscriptPath
        if ($latest) {
            $global:transcriptPath = $latest
        }
    }

    if (-not $global:transcriptPath -or -not (Test-Path $global:transcriptPath)) {
        $lblStatus.Text = "Status: No chat found"
        return
    }

    try {
        $fileInfo = New-Object System.IO.FileInfo($global:transcriptPath)
        $global:lastFilePos = $fileInfo.Length

        # Lectura con FileShare.ReadWrite para evitar bloqueos con el IDE
        $fileStream = [System.IO.File]::Open($global:transcriptPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $streamReader = New-Object System.IO.StreamReader($fileStream, [System.Text.Encoding]::UTF8)
        $lines = New-Object System.Collections.Generic.List[string]
        while (($line = $streamReader.ReadLine()) -ne $null) {
            $lines.Add($line)
        }
        $streamReader.Close()
        $fileStream.Close()

        $lastFoundContent = $null

        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            $l = $lines[$i]
            if ($l -match '"source":"MODEL"' -and $l -match '"type":"PLANNER_RESPONSE"') {
                try {
                    $json = $l | ConvertFrom-Json
                    if ($json.content -and (-not [string]::IsNullOrWhiteSpace($json.content))) {
                        $lastFoundContent = $json.content
                        break
                    }
                }
                catch {}
            }
        }

        if ($lastFoundContent) {
            $targetLang = "es"
            switch ($cmbLang.SelectedIndex) {
                1 { $targetLang = "es" }
                2 { $targetLang = "de" }
                3 { $targetLang = "en" }
                default { $targetLang = Detect-Language $lastFoundContent }
            }

            if ($voiceMap[$targetLang]) {
                try { $synth.SelectVoice($voiceMap[$targetLang]) } catch {}
            }

            $flag = switch ($targetLang) {
                "de" { "[DE]" }
                "en" { "[EN]" }
                default { "[ES]" }
            }

            $text = Normalize-Text $lastFoundContent $targetLang

            $global:lastText = $text
            $txtSpeech.Text = $text
            $lblStatus.Text = "Status: Reading $flag"
            $btnPlayPause.Text = "Pause"

            if ($speakImmediately) {
                $synth.SpeakAsyncCancelAll()
                [System.Threading.Thread]::Sleep(50)
                $synth.SpeakAsync($text) | Out-Null
            }
        }
        else {
            $lblStatus.Text = "Status: No messages"
        }
    }
    catch {
        $lblStatus.Text = "Status: Error reading chat"
    }
}

# Inicialización del puntero del archivo y precarga de la última respuesta
if ($global:transcriptPath -and (Test-Path $global:transcriptPath)) {
    $fileInfo = New-Object System.IO.FileInfo($global:transcriptPath)
    $global:lastFilePos = $fileInfo.Length
    Update-LatestSpeech -speakImmediately $false
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

$btnReload.Add_Click({
    Update-LatestSpeech -speakImmediately $true
})

# Lógica del Timer (monitorea asíncronamente el archivo sin bloquear la UI)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    # Si ConversationId es auto, verificar cada 2 segundos si se abrió una nueva conversación en el IDE
    if ($ConversationId -eq "auto") {
        $global:autoCheckCounter++
        if ($global:autoCheckCounter % 2 -eq 0) {
            $latest = Get-LatestTranscriptPath
            if ($latest -and $latest -ne $global:transcriptPath) {
                $global:transcriptPath = $latest
                $global:lastFilePos = 0
            }
        }
    }

    if ($global:transcriptPath -and (Test-Path $global:transcriptPath)) {
        $fileInfo = New-Object System.IO.FileInfo($global:transcriptPath)
        
        if ($fileInfo.Length -lt $global:lastFilePos) {
            $global:lastFilePos = 0
        }

        if ($fileInfo.Length -gt $global:lastFilePos) {
            $stream = $fileInfo.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            $stream.Position = $global:lastFilePos
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
            $newContent = $reader.ReadToEnd()
            $global:lastFilePos = $stream.Position
            $reader.Close()
            $stream.Close()
        
            $newLines = $newContent -split "`n"
            $latestModelContent = $null

            foreach ($line in $newLines) {
                if ($line -match '"source":"MODEL"' -and $line -match '"type":"PLANNER_RESPONSE"') {
                    try {
                        $json = $line | ConvertFrom-Json
                        if ($json.content -and (-not [string]::IsNullOrWhiteSpace($json.content))) {
                            $latestModelContent = $json.content
                        }
                    }
                    catch {}
                }
            }

            if ($latestModelContent) {
                $targetLang = "es"
                switch ($cmbLang.SelectedIndex) {
                    1 { $targetLang = "es" }
                    2 { $targetLang = "de" }
                    3 { $targetLang = "en" }
                    default { $targetLang = Detect-Language $latestModelContent }
                }

                if ($voiceMap[$targetLang]) {
                    try { $synth.SelectVoice($voiceMap[$targetLang]) } catch {}
                }

                $flag = switch ($targetLang) {
                    "de" { "[DE]" }
                    "en" { "[EN]" }
                    default { "[ES]" }
                }

                $text = Normalize-Text $latestModelContent $targetLang

                $global:lastText = $text
                $txtSpeech.Text = $text
                $lblStatus.Text = "Status: Reading $flag"
                $btnPlayPause.Text = "Pause"
                
                $synth.SpeakAsyncCancelAll()
                $synth.SpeakAsync($text) | Out-Null
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

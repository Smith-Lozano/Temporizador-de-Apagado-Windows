# ============================================
# TEMPORIZADOR DE APAGADO WINDOWS
# Version: 2.0
# ============================================

# Habilitar ejecucion
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Cargar librerias
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Variables
$global:shutdownTimer = $null
$global:scheduledTime = $null
$global:warningShown = $false

# ============================================
# FUNCIONES BASICAS
# ============================================
function Show-Message {
    param([string]$title, [string]$msg, [string]$type = "info")
    
    if ($type -eq "warning") {
        [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
    elseif ($type -eq "error") {
        [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

function Show-OneMinuteWarning {
    $warningForm = New-Object System.Windows.Forms.Form
    $warningForm.Text = "ALERTA DE APAGADO"
    $warningForm.Size = New-Object System.Drawing.Size(600, 400)
    $warningForm.StartPosition = "CenterScreen"
    $warningForm.BackColor = [System.Drawing.Color]::FromArgb(192, 0, 0)
    $warningForm.TopMost = $true
    $warningForm.ControlBox = $false
    
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = "ATENCION!`n`nEL EQUIPO SE APAGARA EN 1 MINUTO`n`nGUARDE TODO SU TRABAJO INMEDIATAMENTE"
    $warningLabel.Size = New-Object System.Drawing.Size(580, 250)
    $warningLabel.Location = New-Object System.Drawing.Point(10, 20)
    $warningLabel.Font = New-Object System.Drawing.Font("Arial Black", 16, [System.Drawing.FontStyle]::Bold)
    $warningLabel.ForeColor = [System.Drawing.Color]::White
    $warningLabel.TextAlign = "MiddleCenter"
    $warningForm.Controls.Add($warningLabel)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "ENTENDIDO"
    $okButton.Size = New-Object System.Drawing.Size(200, 50)
    $okButton.Location = New-Object System.Drawing.Point(200, 280)
    $okButton.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = [System.Drawing.Color]::Black
    $okButton.FlatStyle = "Flat"
    $okButton.Add_Click({ $warningForm.Close() })
    $warningForm.Controls.Add($okButton)
    
    [System.Media.SystemSounds]::Hand.Play()
    $warningForm.ShowDialog()
}

# ============================================
# FUNCION PRINCIPAL
# ============================================
function Start-ShutdownTimer {
    param([int]$minutes)
    
    Write-Host "Programando apagado en $minutes minutos..."
    
    # Cancelar si hay uno activo
    if ($global:shutdownTimer) {
        $global:shutdownTimer.Stop()
        $global:shutdownTimer.Dispose()
        $global:shutdownTimer = $null
    }
    
    $global:warningShown = $false
    $seconds = $minutes * 60
    $global:scheduledTime = (Get-Date).AddSeconds($seconds)
    
    # Mostrar confirmacion
    $message = "El equipo se apagara en $minutes minutos`n`n" +
               "Hora programada: $($global:scheduledTime.ToString('HH:mm:ss'))`n`n" +
               "Se forzara el cierre de todas las aplicaciones"
    
    Show-Message "Apagado Programado" $message "info"
    
    # Actualizar estado
    $labelStatus.Text = "Apagando en: $minutes minutos ($($global:scheduledTime.ToString('HH:mm:ss')))"
    $labelStatus.ForeColor = [System.Drawing.Color]::Orange
    $buttonCancel.Enabled = $true
    
    # Crear temporizador
    $global:shutdownTimer = New-Object System.Windows.Forms.Timer
    $global:shutdownTimer.Interval = 1000
    
    $global:shutdownTimer.Add_Tick({
        $now = Get-Date
        $remaining = $global:scheduledTime - $now
        $totalSeconds = [math]::Max(0, [math]::Ceiling($remaining.TotalSeconds))
        
        if ($totalSeconds -le 0) {
            # Apagar
            $global:shutdownTimer.Stop()
            $labelStatus.Text = "APAGANDO AHORA!"
            $labelStatus.ForeColor = [System.Drawing.Color]::Red
            $form.Refresh()
            Start-Sleep -Seconds 2
            
            # Apagado forzado
            shutdown.exe /s /f /t 0
            $form.Close()
        }
        else {
            # Actualizar contador
            $remainingMinutes = [math]::Floor($totalSeconds / 60)
            $remainingSeconds = $totalSeconds % 60
            $labelStatus.Text = "Apagando en: ${remainingMinutes}:${remainingSeconds:D2} minutos"
            
            # Alerta de 1 minuto
            if ($totalSeconds -le 60 -and -not $global:warningShown) {
                $global:warningShown = $true
                Show-OneMinuteWarning
            }
        }
    })
    
    $global:shutdownTimer.Start()
}

function Cancel-Shutdown {
    if ($global:shutdownTimer) {
        $global:shutdownTimer.Stop()
        $global:shutdownTimer.Dispose()
        $global:shutdownTimer = $null
    }
    
    # Cancelar apagado
    shutdown.exe /a 2>$null
    
    $global:scheduledTime = $null
    $global:warningShown = $false
    
    $labelStatus.Text = "Estado: Listo"
    $labelStatus.ForeColor = [System.Drawing.Color]::LightGreen
    $buttonCancel.Enabled = $false
    
    Show-Message "Apagado Cancelado" "El apagado programado ha sido cancelado." "info"
}

# ============================================
# INTERFAZ GRAFICA
# ============================================

# Crear formulario
$form = New-Object System.Windows.Forms.Form
$form.Text = "Temporizador de Apagado Windows v2.0 | by smith"
$form.Size = New-Object System.Drawing.Size(615, 550)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.MaximizeBox = $false

# Titulo
$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "TEMPORIZADOR DE APAGADO WINDOWS"
$labelTitle.Size = New-Object System.Drawing.Size(580, 50)
$labelTitle.Location = New-Object System.Drawing.Point(10, 10)
$labelTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$labelTitle.TextAlign = "MiddleCenter"
$labelTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 184, 212)
$form.Controls.Add($labelTitle)

# Descripcion
$labelDesc = New-Object System.Windows.Forms.Label
$labelDesc.Text = "Seleccione el tiempo para apagar el equipo:"
$labelDesc.Size = New-Object System.Drawing.Size(580, 30)
$labelDesc.Location = New-Object System.Drawing.Point(10, 70)
$labelDesc.TextAlign = "MiddleCenter"
$labelDesc.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$form.Controls.Add($labelDesc)

# Panel para botones
$panel = New-Object System.Windows.Forms.Panel
$panel.Size = New-Object System.Drawing.Size(560, 180)
$panel.Location = New-Object System.Drawing.Point(20, 110)
$panel.BackColor = [System.Drawing.Color]::FromArgb(62, 62, 66)
$panel.BorderStyle = "FixedSingle"
$form.Controls.Add($panel)

# ============================================
# CREAR BOTONES DE FORMA DIRECTA - ESTO SI FUNCIONA
# ============================================

# Boton 5 minutos
$button5 = New-Object System.Windows.Forms.Button
$button5.Text = "5 min"
$button5.Size = New-Object System.Drawing.Size(90, 45)
$button5.Location = New-Object System.Drawing.Point(20, 20)
$button5.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button5.BackColor = [System.Drawing.Color]::FromArgb(33, 150, 243)
$button5.ForeColor = [System.Drawing.Color]::White
$button5.FlatStyle = "Flat"
$button5.FlatAppearance.BorderSize = 0
$button5.Cursor = "Hand"
$button5.Add_Click({ Start-ShutdownTimer 5 })
$panel.Controls.Add($button5)

# Boton 10 minutos
$button10 = New-Object System.Windows.Forms.Button
$button10.Text = "10 min"
$button10.Size = New-Object System.Drawing.Size(90, 45)
$button10.Location = New-Object System.Drawing.Point(125, 20)
$button10.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button10.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$button10.ForeColor = [System.Drawing.Color]::White
$button10.FlatStyle = "Flat"
$button10.FlatAppearance.BorderSize = 0
$button10.Cursor = "Hand"
$button10.Add_Click({ Start-ShutdownTimer 10 })
$panel.Controls.Add($button10)

# Boton 15 minutos
$button15 = New-Object System.Windows.Forms.Button
$button15.Text = "15 min"
$button15.Size = New-Object System.Drawing.Size(90, 45)
$button15.Location = New-Object System.Drawing.Point(230, 20)
$button15.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button15.BackColor = [System.Drawing.Color]::FromArgb(156, 39, 176)
$button15.ForeColor = [System.Drawing.Color]::White
$button15.FlatStyle = "Flat"
$button15.FlatAppearance.BorderSize = 0
$button15.Cursor = "Hand"
$button15.Add_Click({ Start-ShutdownTimer 15 })
$panel.Controls.Add($button15)

# Boton 30 minutos
$button30 = New-Object System.Windows.Forms.Button
$button30.Text = "30 min"
$button30.Size = New-Object System.Drawing.Size(90, 45)
$button30.Location = New-Object System.Drawing.Point(335, 20)
$button30.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button30.BackColor = [System.Drawing.Color]::FromArgb(255, 87, 34)
$button30.ForeColor = [System.Drawing.Color]::White
$button30.FlatStyle = "Flat"
$button30.FlatAppearance.BorderSize = 0
$button30.Cursor = "Hand"
$button30.Add_Click({ Start-ShutdownTimer 30 })
$panel.Controls.Add($button30)

# Boton 45 minutos
$button45 = New-Object System.Windows.Forms.Button
$button45.Text = "45 min"
$button45.Size = New-Object System.Drawing.Size(90, 45)
$button45.Location = New-Object System.Drawing.Point(440, 20)
$button45.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button45.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$button45.ForeColor = [System.Drawing.Color]::White
$button45.FlatStyle = "Flat"
$button45.FlatAppearance.BorderSize = 0
$button45.Cursor = "Hand"
$button45.Add_Click({ Start-ShutdownTimer 45 })
$panel.Controls.Add($button45)

# Boton 60 minutos
$button60 = New-Object System.Windows.Forms.Button
$button60.Text = "60 min"
$button60.Size = New-Object System.Drawing.Size(90, 45)
$button60.Location = New-Object System.Drawing.Point(20, 80)
$button60.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button60.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
$button60.ForeColor = [System.Drawing.Color]::White
$button60.FlatStyle = "Flat"
$button60.FlatAppearance.BorderSize = 0
$button60.Cursor = "Hand"
$button60.Add_Click({ Start-ShutdownTimer 60 })
$panel.Controls.Add($button60)

# Boton 90 minutos
$button90 = New-Object System.Windows.Forms.Button
$button90.Text = "90 min"
$button90.Size = New-Object System.Drawing.Size(90, 45)
$button90.Location = New-Object System.Drawing.Point(125, 80)
$button90.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button90.BackColor = [System.Drawing.Color]::FromArgb(63, 81, 181)
$button90.ForeColor = [System.Drawing.Color]::White
$button90.FlatStyle = "Flat"
$button90.FlatAppearance.BorderSize = 0
$button90.Cursor = "Hand"
$button90.Add_Click({ Start-ShutdownTimer 90 })
$panel.Controls.Add($button90)

# Boton 120 minutos
$button120 = New-Object System.Windows.Forms.Button
$button120.Text = "120 min"
$button120.Size = New-Object System.Drawing.Size(90, 45)
$button120.Location = New-Object System.Drawing.Point(230, 80)
$button120.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button120.BackColor = [System.Drawing.Color]::FromArgb(233, 30, 99)
$button120.ForeColor = [System.Drawing.Color]::White
$button120.FlatStyle = "Flat"
$button120.FlatAppearance.BorderSize = 0
$button120.Cursor = "Hand"
$button120.Add_Click({ Start-ShutdownTimer 120 })
$panel.Controls.Add($button120)

# Boton 150 minutos
$button150 = New-Object System.Windows.Forms.Button
$button150.Text = "150 min"
$button150.Size = New-Object System.Drawing.Size(90, 45)
$button150.Location = New-Object System.Drawing.Point(335, 80)
$button150.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button150.BackColor = [System.Drawing.Color]::FromArgb(255, 193, 7)
$button150.ForeColor = [System.Drawing.Color]::Black
$button150.FlatStyle = "Flat"
$button150.FlatAppearance.BorderSize = 0
$button150.Cursor = "Hand"
$button150.Add_Click({ Start-ShutdownTimer 150 })
$panel.Controls.Add($button150)

# Boton 180 minutos
$button180 = New-Object System.Windows.Forms.Button
$button180.Text = "180 min"
$button180.Size = New-Object System.Drawing.Size(90, 45)
$button180.Location = New-Object System.Drawing.Point(440, 80)
$button180.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$button180.BackColor = [System.Drawing.Color]::FromArgb(158, 158, 158)
$button180.ForeColor = [System.Drawing.Color]::White
$button180.FlatStyle = "Flat"
$button180.FlatAppearance.BorderSize = 0
$button180.Cursor = "Hand"
$button180.Add_Click({ Start-ShutdownTimer 180 })
$panel.Controls.Add($button180)

# ============================================
# TIEMPO PERSONALIZADO
# ============================================

$panelCustom = New-Object System.Windows.Forms.Panel
$panelCustom.Size = New-Object System.Drawing.Size(560, 70)
$panelCustom.Location = New-Object System.Drawing.Point(20, 300)
$panelCustom.BackColor = [System.Drawing.Color]::FromArgb(62, 62, 66)
$panelCustom.BorderStyle = "FixedSingle"
$form.Controls.Add($panelCustom)

$labelCustom = New-Object System.Windows.Forms.Label
$labelCustom.Text = "O ingrese tiempo personalizado (minutos):"
$labelCustom.Size = New-Object System.Drawing.Size(300, 30)
$labelCustom.Location = New-Object System.Drawing.Point(20, 20)
$labelCustom.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$panelCustom.Controls.Add($labelCustom)

$textBoxCustom = New-Object System.Windows.Forms.TextBox
$textBoxCustom.Size = New-Object System.Drawing.Size(80, 30)
$textBoxCustom.Location = New-Object System.Drawing.Point(330, 20)
$textBoxCustom.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 55)
$textBoxCustom.ForeColor = [System.Drawing.Color]::White
$textBoxCustom.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$panelCustom.Controls.Add($textBoxCustom)

$buttonCustom = New-Object System.Windows.Forms.Button
$buttonCustom.Text = "Establecer"
$buttonCustom.Size = New-Object System.Drawing.Size(100, 30)
$buttonCustom.Location = New-Object System.Drawing.Point(420, 20)
$buttonCustom.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$buttonCustom.ForeColor = [System.Drawing.Color]::White
$buttonCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$buttonCustom.FlatStyle = "Flat"
$buttonCustom.Cursor = "Hand"
$buttonCustom.Add_Click({
    if ($textBoxCustom.Text -match '^\d+$' -and [int]$textBoxCustom.Text -gt 0) {
        Start-ShutdownTimer ([int]$textBoxCustom.Text)
    } else {
        Show-Message "Entrada invalida" "Por favor, ingrese un numero valido mayor que 0." "warning"
    }
})
$panelCustom.Controls.Add($buttonCustom)

# Estado
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Estado: Listo"
$labelStatus.Size = New-Object System.Drawing.Size(560, 35)
$labelStatus.Location = New-Object System.Drawing.Point(20, 380)
$labelStatus.TextAlign = "MiddleCenter"
$labelStatus.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$labelStatus.ForeColor = [System.Drawing.Color]::LightGreen
$labelStatus.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 45)
$labelStatus.BorderStyle = "FixedSingle"
$form.Controls.Add($labelStatus)

# Botones de control
$panelControl = New-Object System.Windows.Forms.Panel
$panelControl.Size = New-Object System.Drawing.Size(560, 60)
$panelControl.Location = New-Object System.Drawing.Point(20, 420)
$form.Controls.Add($panelControl)

# Boton Cancelar
$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Text = "Cancelar Apagado"
$buttonCancel.Size = New-Object System.Drawing.Size(140, 45)
$buttonCancel.Location = New-Object System.Drawing.Point(0, 10)
$buttonCancel.BackColor = [System.Drawing.Color]::FromArgb(211, 47, 47)
$buttonCancel.ForeColor = [System.Drawing.Color]::White
$buttonCancel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$buttonCancel.FlatStyle = "Flat"
$buttonCancel.Cursor = "Hand"
$buttonCancel.Enabled = $false
$buttonCancel.Add_Click({ Cancel-Shutdown })
$panelControl.Controls.Add($buttonCancel)

# Boton Apagar Ahora
$buttonNow = New-Object System.Windows.Forms.Button
$buttonNow.Text = "Apagar Ahora"
$buttonNow.Size = New-Object System.Drawing.Size(140, 45)
$buttonNow.Location = New-Object System.Drawing.Point(420, 10)
$buttonNow.BackColor = [System.Drawing.Color]::FromArgb(255, 87, 34)
$buttonNow.ForeColor = [System.Drawing.Color]::White
$buttonNow.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$buttonNow.FlatStyle = "Flat"
$buttonNow.Cursor = "Hand"
$buttonNow.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "¿Esta seguro que desea apagar el equipo ahora?",
        "Confirmar Apagado",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq "Yes") {
        shutdown.exe /s /f /t 0
    }
})
$panelControl.Controls.Add($buttonNow)

# ============================================
# EJECUTAR
# ============================================
$form.Add_FormClosing({
    if ($global:shutdownTimer) {
        $global:shutdownTimer.Stop()
        $global:shutdownTimer.Dispose()
    }
})

$form.ShowDialog()
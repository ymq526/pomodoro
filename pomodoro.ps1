Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Time settings (seconds)
$WORK_SEC     = 25 * 60
$SHORT_SEC    = 5  * 60
$LONG_SEC     = 15 * 60
$MAX_SESSIONS = 4

# Mutable state
$script:timeLeft   = $WORK_SEC
$script:totalTime  = $WORK_SEC
$script:running    = $false
$script:mode       = 0   # 0=Work  1=Short Break  2=Long Break
$script:sessions   = 0   # completed work sessions

# Color palette (Catppuccin Mocha)
$C_BG      = [Drawing.Color]::FromArgb(24,  24,  37)
$C_SURFACE = [Drawing.Color]::FromArgb(49,  50,  68)
$C_SUBTLE  = [Drawing.Color]::FromArgb(108, 112, 134)
$C_TEXT    = [Drawing.Color]::FromArgb(205, 214, 244)
$C_WORK    = [Drawing.Color]::FromArgb(243, 139, 168)  # pink
$C_SHORT   = [Drawing.Color]::FromArgb(166, 227, 161)  # green
$C_LONG    = [Drawing.Color]::FromArgb(137, 180, 250)  # blue

$COLORS  = @($C_WORK, $C_SHORT, $C_LONG)
$TIMES   = @($WORK_SEC, $SHORT_SEC, $LONG_SEC)
$BTNTXT = @(
    (-join [char[]]@(0x5DE5, 0x4F5C)),          # 工作
    (-join [char[]]@(0x77ED, 0x4F11, 0x606F)),  # 短休息
    (-join [char[]]@(0x957F, 0x4F11, 0x606F))   # 长休息
)

function Format-Time([int]$s) { '{0:D2}:{1:D2}' -f [int]($s / 60), ($s % 60) }

function Update-UI {
    $startBtn.BackColor  = $COLORS[$script:mode]
    $startBtn.Text       = if ($script:running) {
        [char]0x6682 + [char]0x505C   # 暂停
    } else {
        [char]0x5F00 + [char]0x59CB   # 开始
    }
    $sessionLabel.Text = ([char]0x5DF2 + [char]0x5B8C + [char]0x6210 + ' ' +
                          $script:sessions + ' ' +
                          [char]0x4E2A + [char]0x756A + [char]0x8304 + [char]0x949F)

    for ($i = 0; $i -lt 3; $i++) {
        if ($i -eq $script:mode) {
            $modeButtons[$i].BackColor = $COLORS[$i]
            $modeButtons[$i].ForeColor = $C_BG
        } else {
            $modeButtons[$i].BackColor = $C_SURFACE
            $modeButtons[$i].ForeColor = $C_TEXT
        }
    }

    $filled = $script:sessions % $MAX_SESSIONS
    for ($i = 0; $i -lt $MAX_SESSIONS; $i++) {
        $dots[$i].BackColor = if ($i -lt $filled) { $C_WORK } else { $C_SURFACE }
    }

    $circlePanel.Invalidate()
}

function Switch-Mode([int]$m) {
    $script:running   = $false
    $timer.Stop()
    $script:mode      = $m
    $script:timeLeft  = $TIMES[$m]
    $script:totalTime = $TIMES[$m]
    Update-UI
}

function Complete-Session {
    $timer.Stop()
    $script:running = $false
    try { [System.Media.SystemSounds]::Exclamation.Play() } catch {}

    if ($script:mode -eq 0) {
        $script:sessions++
        Update-UI
        $nextMode = if ($script:sessions % $MAX_SESSIONS -eq 0) { 2 } else { 1 }
        $msg = ([char]0x4E13 + [char]0x6CE8 + [char]0x65F6 + [char]0x95F4 + [char]0x7ED3 + [char]0x675F +
                [char]0xFF01 + [char]0x53BB + [char]0x4F11 + [char]0x606F + [char]0x4E00 + [char]0x4E0B + [char]0x5427)
    } else {
        $nextMode = 0
        $msg = ([char]0x4F11 + [char]0x606F + [char]0x65F6 + [char]0x95F4 + [char]0x7ED3 + [char]0x675F +
                [char]0xFF01 + [char]0x51C6 + [char]0x5907 + [char]0x597D + [char]0x7EE7 + [char]0x7EED +
                [char]0x5DE5 + [char]0x4F5C + [char]0x4E86 + [char]0x5417 + [char]0xFF1F)
    }

    $title = [char]0x756A + [char]0x8304 + [char]0x949F
    [Windows.Forms.MessageBox]::Show($msg, $title, 'OK', 'Information') | Out-Null
    Switch-Mode $nextMode
}

# ── Form ──────────────────────────────────────────────────────────────────────
$form = New-Object Windows.Forms.Form
$form.Text            = [char]0x756A + [char]0x8304 + [char]0x949F   # 番茄钟
$form.ClientSize      = New-Object Drawing.Size(380, 520)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $C_BG
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox     = $false
$form.KeyPreview      = $true
$form.GetType().GetProperty('DoubleBuffered', 36).SetValue($form, $true)

# Title
$titleLbl = New-Object Windows.Forms.Label
$titleLbl.Text      = [char]0x756A + [char]0x8304 + [char]0x949F    # 番茄钟
$titleLbl.Font      = New-Object Drawing.Font('Segoe UI', 16, [Drawing.FontStyle]::Bold)
$titleLbl.ForeColor = $C_TEXT
$titleLbl.BackColor = $C_BG
$titleLbl.TextAlign = 'MiddleCenter'
$titleLbl.SetBounds(0, 12, 380, 40)
$form.Controls.Add($titleLbl)

# ── Circle panel (custom drawing) ─────────────────────────────────────────────
$circlePanel = New-Object Windows.Forms.Panel
$circlePanel.SetBounds(70, 60, 240, 240)
$circlePanel.BackColor = $C_BG
$circlePanel.GetType().GetProperty('DoubleBuffered', 36).SetValue($circlePanel, $true)
$form.Controls.Add($circlePanel)

$circlePanel.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode     = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $pad  = 14.0
    $diam = 240.0 - 2 * $pad
    $rect = [Drawing.RectangleF]::new($pad, $pad, $diam, $diam)
    $rw   = 12.0

    # Background ring
    $bgPen = New-Object Drawing.Pen($C_SURFACE, $rw)
    $g.DrawEllipse($bgPen, $rect)
    $bgPen.Dispose()

    # Foreground arc (remaining time, clockwise from top)
    $pct   = if ($script:totalTime -gt 0) { [float]$script:timeLeft / $script:totalTime } else { 0.0 }
    $sweep = [Math]::Min(359.9, [Math]::Max(0.5, 360.0 * $pct))
    $clr   = $COLORS[$script:mode]

    $fgPen = New-Object Drawing.Pen($clr, $rw)
    $fgPen.StartCap = [Drawing.Drawing2D.LineCap]::Round
    $fgPen.EndCap   = [Drawing.Drawing2D.LineCap]::Round
    $g.DrawArc($fgPen, $rect, -90.0, $sweep)
    $fgPen.Dispose()

    # Time display in center
    $font  = New-Object Drawing.Font('Segoe UI', 36, [Drawing.FontStyle]::Bold)
    $brush = New-Object Drawing.SolidBrush($C_TEXT)
    $sf    = New-Object Drawing.StringFormat
    $sf.Alignment     = [Drawing.StringAlignment]::Center
    $sf.LineAlignment = [Drawing.StringAlignment]::Center
    $g.DrawString(
        (Format-Time $script:timeLeft), $font, $brush,
        [Drawing.RectangleF]::new(0, 0, 240, 240), $sf
    )
    $font.Dispose(); $brush.Dispose(); $sf.Dispose()
})

# ── Mode-switch buttons ────────────────────────────────────────────────────────
$modeButtons = @()
$bw = 100; $bh = 32; $by = 312; $bx0 = 35
for ($i = 0; $i -lt 3; $i++) {
    $mb = New-Object Windows.Forms.Button
    $mb.SetBounds($bx0 + $i * 107, $by, $bw, $bh)
    $mb.Text      = $BTNTXT[$i]
    $mb.FlatStyle = 'Flat'
    $mb.FlatAppearance.BorderSize = 0
    $mb.Font      = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
    $mb.Cursor    = 'Hand'
    $mb.Tag       = $i
    $mb.Add_Click({ param($s, $e) Switch-Mode ([int]$s.Tag) })
    $modeButtons += $mb
    $form.Controls.Add($mb)
}

# ── Start / Pause button ───────────────────────────────────────────────────────
$startBtn = New-Object Windows.Forms.Button
$startBtn.SetBounds(95, 392, 190, 52)
$startBtn.Text      = [char]0x5F00 + [char]0x59CB   # 开始
$startBtn.Font      = New-Object Drawing.Font('Segoe UI', 15, [Drawing.FontStyle]::Bold)
$startBtn.BackColor = $C_WORK
$startBtn.ForeColor = $C_BG
$startBtn.FlatStyle = 'Flat'
$startBtn.FlatAppearance.BorderSize = 0
$startBtn.Cursor    = 'Hand'
$startBtn.Add_Click({
    $script:running = -not $script:running
    if ($script:running) { $timer.Start() } else { $timer.Stop() }
    Update-UI
})
$form.Controls.Add($startBtn)

# ── Reset button ──────────────────────────────────────────────────────────────
$resetBtn = New-Object Windows.Forms.Button
$resetBtn.SetBounds(10, 392, 75, 52)
$resetBtn.Text      = [char]0x91CD + [char]0x7F6E   # 重置
$resetBtn.Font      = New-Object Drawing.Font('Segoe UI', 11)
$resetBtn.BackColor = $C_SURFACE
$resetBtn.ForeColor = $C_SUBTLE
$resetBtn.FlatStyle = 'Flat'
$resetBtn.FlatAppearance.BorderSize = 0
$resetBtn.Cursor    = 'Hand'
$resetBtn.Add_Click({
    $script:running   = $false
    $timer.Stop()
    $script:timeLeft  = $TIMES[$script:mode]
    $script:totalTime = $TIMES[$script:mode]
    Update-UI
})
$form.Controls.Add($resetBtn)

# ── Skip button ───────────────────────────────────────────────────────────────
$skipBtn = New-Object Windows.Forms.Button
$skipBtn.SetBounds(295, 392, 75, 52)
$skipBtn.Text      = [char]0x8DF3 + [char]0x8FC7   # 跳过
$skipBtn.Font      = New-Object Drawing.Font('Segoe UI', 11)
$skipBtn.BackColor = $C_SURFACE
$skipBtn.ForeColor = $C_SUBTLE
$skipBtn.FlatStyle = 'Flat'
$skipBtn.FlatAppearance.BorderSize = 0
$skipBtn.Cursor    = 'Hand'
$skipBtn.Add_Click({ Complete-Session })
$form.Controls.Add($skipBtn)

# ── Session dots (4 tomatoes) ─────────────────────────────────────────────────
$dots  = @()
$dotSz = 14; $dotSp = 26; $dotY = 460
$dotX0 = [int]((380 - (($MAX_SESSIONS - 1) * $dotSp + $dotSz)) / 2)
for ($i = 0; $i -lt $MAX_SESSIONS; $i++) {
    $d = New-Object Windows.Forms.Panel
    $d.SetBounds($dotX0 + $i * $dotSp, $dotY, $dotSz, $dotSz)
    $d.BackColor = $C_SURFACE
    $gp = New-Object Drawing.Drawing2D.GraphicsPath
    $gp.AddEllipse(0, 0, $dotSz, $dotSz)
    $d.Region = New-Object Drawing.Region($gp)
    $dots += $d
    $form.Controls.Add($d)
}

# Session count label
$sessionLabel = New-Object Windows.Forms.Label
$sessionLabel.SetBounds(0, 480, 380, 24)
$sessionLabel.TextAlign = 'MiddleCenter'
$sessionLabel.ForeColor = $C_SUBTLE
$sessionLabel.BackColor = $C_BG
$sessionLabel.Font      = New-Object Drawing.Font('Segoe UI', 9)
$sessionLabel.Text      = [char]0x5DF2 + [char]0x5B8C + [char]0x6210 + ' 0 ' +
                           [char]0x4E2A + [char]0x756A + [char]0x8304 + [char]0x949F
$form.Controls.Add($sessionLabel)

# ── Keyboard shortcuts ────────────────────────────────────────────────────────
$form.Add_KeyDown({
    param($s, $e)
    if ($e.KeyCode -eq [Windows.Forms.Keys]::Space) {
        $startBtn.PerformClick()
        $e.Handled = $true
    } elseif ($e.KeyCode -eq [Windows.Forms.Keys]::R) {
        $resetBtn.PerformClick()
        $e.Handled = $true
    } elseif ($e.KeyCode -eq [Windows.Forms.Keys]::N) {
        $skipBtn.PerformClick()
        $e.Handled = $true
    }
})

# ── Countdown timer ───────────────────────────────────────────────────────────
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    if ($script:timeLeft -gt 0) {
        $script:timeLeft--
        $circlePanel.Invalidate()
    } else {
        Complete-Session
    }
})

# ── Run ───────────────────────────────────────────────────────────────────────
Update-UI
[Windows.Forms.Application]::Run($form)
$timer.Dispose()
$form.Dispose()

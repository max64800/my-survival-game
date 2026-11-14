# Dwarf Game play-session report.
#
# Started by auto_record.ps1 after each play session. In plain words:
#   1. (Only with -AskFeedback) pops up "How was it?" -> feedback.txt. Normally the owner tells Claude in chat.
#   2. Takes snapshots from the video (about 60 at most) -> snapshots\
#   3. Runs Claude in the background, READ-ONLY, to compare what the owner said
#      with what the snapshots and the game's log show -> report.md
#   4. Shows a little "report ready" bubble near the clock.
#
# Claude here can only read files. It cannot change the game. Fixes happen
# later, in a normal chat, after the owner has seen the report.
#
# Usage: powershell -STA -ExecutionPolicy Bypass -File session_report.ps1 -SessionDir "<folder>" [-NoClaude] [-AskFeedback]

param(
    [Parameter(Mandatory = $true)][string]$SessionDir,
    [switch]$NoClaude,
    [switch]$AskFeedback   # off by default: the owner gives feedback in the chat instead
)

$ErrorActionPreference = 'Stop'
$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$LogFile    = Join-Path $env:LOCALAPPDATA 'DwarfGameRecorder\recorder.log'
$Video      = Join-Path $SessionDir 'video.mp4'
$ShotsDir   = Join-Path $SessionDir 'snapshots'
$Report     = Join-Path $SessionDir 'report.md'
$MaxShots   = 60
$Utf8NoBom  = New-Object Text.UTF8Encoding $false

function Log([string]$msg) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  [report] ' + $msg
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class DwarfShow {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
# This script is started "hidden", and Windows applies "hidden" to the FIRST window
# a program shows, which would make the feedback box invisible. Spend that first
# call on the (already hidden) console window instead.
[DwarfShow]::ShowWindow([DwarfShow]::GetConsoleWindow(), 0) | Out-Null

# ---------------------------------------------------------------- 1. feedback box

function Ask-Feedback {
    $form = New-Object Windows.Forms.Form
    $form.Text = 'Dwarf Game - how was it?'
    $form.Size = New-Object Drawing.Size(560, 380)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.Font = New-Object Drawing.Font('Segoe UI', 10)

    $label = New-Object Windows.Forms.Label
    $label.Text = "How was it? Anything broken, weird, too hard, too easy, or not fun?`r`nA few words is enough. Claude will compare this with the video."
    $label.Location = New-Object Drawing.Point(14, 12)
    $label.Size = New-Object Drawing.Size(520, 48)
    $form.Controls.Add($label)

    $box = New-Object Windows.Forms.TextBox
    $box.Multiline = $true
    $box.ScrollBars = 'Vertical'
    $box.AcceptsReturn = $true
    $box.Location = New-Object Drawing.Point(14, 64)
    $box.Size = New-Object Drawing.Size(516, 210)
    $form.Controls.Add($box)

    $send = New-Object Windows.Forms.Button
    $send.Text = 'Send'
    $send.Location = New-Object Drawing.Point(330, 288)
    $send.Size = New-Object Drawing.Size(96, 34)
    $send.DialogResult = [Windows.Forms.DialogResult]::OK
    $form.Controls.Add($send)

    $skip = New-Object Windows.Forms.Button
    $skip.Text = 'Skip'
    $skip.Location = New-Object Drawing.Point(434, 288)
    $skip.Size = New-Object Drawing.Size(96, 34)
    $skip.DialogResult = [Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($skip)
    $form.CancelButton = $skip

    # If nobody answers in 15 minutes, close the box and carry on.
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 15 * 60 * 1000
    $timer.Add_Tick({ $timer.Stop(); $form.DialogResult = [Windows.Forms.DialogResult]::Cancel; $form.Close() })
    $form.Add_Shown({
        [DwarfShow]::ShowWindow($form.Handle, 5) | Out-Null   # 5 = show
        [DwarfShow]::SetForegroundWindow($form.Handle) | Out-Null
        $timer.Start(); $form.Activate(); $box.Focus()
    })

    $result = $form.ShowDialog()
    $timer.Stop()
    $text = $box.Text.Trim()
    $form.Dispose()
    if ($result -eq [Windows.Forms.DialogResult]::OK -and $text) { return $text }
    return $null
}

# ---------------------------------------------------------------- 2. snapshots

function Get-VideoSeconds {
    $out = & ffprobe -v error -show_entries format=duration -of csv=p=0 $Video 2>$null
    $sec = 0.0
    [double]::TryParse(("$out").Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$sec) | Out-Null
    return $sec
}

function Make-Snapshots {
    if (-not (Test-Path $Video)) { return 0 }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { Log 'ffmpeg not found; no snapshots.'; return 0 }
    $seconds = Get-VideoSeconds
    if ($seconds -le 0) { return 0 }
    $every = [math]::Max(10, [math]::Ceiling($seconds / $MaxShots))
    New-Item -ItemType Directory -Force -Path $ShotsDir | Out-Null
    # One picture every $every seconds, named by the time it was taken (t0130 = 1 min 30 s).
    $n = 0
    for ($t = [math]::Min(3, $seconds / 2); $t -lt $seconds; $t += $every) {
        $mm = [int][math]::Floor($t / 60); $ss = [int][math]::Floor($t % 60)
        $name = 't{0:00}{1:00}.jpg' -f $mm, $ss
        $tStr = $t.ToString([Globalization.CultureInfo]::InvariantCulture)
        & ffmpeg -v error -y -ss $tStr -i $Video -frames:v 1 -vf 'scale=1280:-2' -q:v 4 (Join-Path $ShotsDir $name) 2>$null
        $n++
    }
    Log "Made $n snapshots (one every $every s)."
    return $n
}

# ---------------------------------------------------------------- 3. Claude's report

function Find-Claude {
    foreach ($name in 'claude.cmd', 'claude.exe', 'claude') {
        $c = Get-Command $name -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
    }
    $npm = Join-Path $env:APPDATA 'npm\claude.cmd'
    if (Test-Path $npm) { return $npm }
    return $null
}

function Run-Claude {
    $claude = Find-Claude
    if (-not $claude) { Log 'Claude CLI not found; no report.'; return }

    # No double quotes inside the prompt: they break the command line. Single quotes are safe.
    $prompt = "Analyze the Dwarf Game play session in the folder '$SessionDir' (the folder name contains spaces). " +
              "Follow the instructions in tools/recorder/analysis_prompt.md exactly. " +
              "Your reply must start with the line '# Play session' and contain only the report."

    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $claude
    # Read-only on purpose: Claude can look, not change anything.
    $psi.Arguments = "-p `"$prompt`" --add-dir `"$SessionDir`" --output-format text --max-turns 80 " +
                     "--allowedTools Read Glob Grep " +
                     "--disallowedTools Bash PowerShell Edit Write NotebookEdit WebFetch WebSearch Agent"
    $psi.WorkingDirectory = $ProjectDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [Text.Encoding]::UTF8

    Log 'Claude is reading the session...'
    $p = [Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $errTask = $p.StandardError.ReadToEndAsync()
    $text = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    $err = $errTask.Result

    if ($p.ExitCode -ne 0 -or -not $text.Trim()) {
        Log "Claude could not finish the report (exit $($p.ExitCode)): $($err.Trim())"
        [IO.File]::WriteAllText((Join-Path $SessionDir 'report-error.txt'), "exit $($p.ExitCode)`r`n$err`r`n$text", $Utf8NoBom)
        return
    }
    # Drop any chatter before the report's first heading.
    $at = $text.IndexOf('# Play session')
    if ($at -gt 0) { $text = $text.Substring($at) }
    [IO.File]::WriteAllText($Report, $text.Trim() + "`r`n", $Utf8NoBom)
    Log "Report ready: $Report"
}

# ---------------------------------------------------------------- 4. bubble near the clock

function Show-Bubble([string]$title, [string]$text) {
    try {
        $icon = New-Object Windows.Forms.NotifyIcon
        $icon.Icon = [Drawing.SystemIcons]::Information
        $icon.Visible = $true
        $icon.BalloonTipTitle = $title
        $icon.BalloonTipText = $text
        $icon.ShowBalloonTip(15000)
        Start-Sleep -Seconds 8
        $icon.Dispose()
    } catch { }
}

# ---------------------------------------------------------------- main

try {
    if (-not (Test-Path $SessionDir)) { throw "No session folder: $SessionDir" }
    Log "Working on $SessionDir"

    if ($AskFeedback) {
        $fb = Ask-Feedback
        if ($fb) {
            [IO.File]::WriteAllText((Join-Path $SessionDir 'feedback.txt'), $fb + "`r`n", $Utf8NoBom)
            Log 'Got feedback.'
        } else { Log 'No feedback given.' }
    }

    $shots = Make-Snapshots

    # Tiny sessions (an accidental start) with no feedback aren't worth a report.
    $info = Get-Content (Join-Path $SessionDir 'session.json') -Raw | ConvertFrom-Json
    $hasFeedback = Test-Path (Join-Path $SessionDir 'feedback.txt')
    if ($NoClaude) { Log 'Skipping Claude (asked not to).' }
    elseif ([double]$info.minutes -lt 0.5 -and -not $hasFeedback) { Log 'Session under 30 s with no feedback; no report.' }
    else {
        Run-Claude
        if (Test-Path $Report) {
            Show-Bubble 'Dwarf Game: play report ready' "Claude looked at your session ($($info.minutes) min). Open 'Dwarf Game Sessions' on your desktop, or just tell Claude 'check my last session'."
        }
    }
} catch {
    Log "Problem: $_"
}

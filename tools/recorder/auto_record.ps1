# Dwarf Game auto-recorder (Windows + OBS).
#
# What it does, in plain words:
#   Every 2 seconds it looks for the Dwarf Game window. When the game opens
#   (from Godot's F5 or an exported build), it tells OBS to record just the
#   game window and the game's sound. When the game closes, it stops.
#   Robot runs (autopilot, netcheck, headless tests) are skipped.
#
# It talks to OBS through OBS's built-in "WebSocket" remote control.
# The password is read from OBS's own settings on this PC (never stored here).
#
# Usage:  powershell -ExecutionPolicy Bypass -File auto_record.ps1 [-Once] [-IncludeRobots]
#   -Once           record one game session, then quit (for testing)
#   -IncludeRobots  also record autopilot runs (for testing)

param([switch]$Once, [switch]$IncludeRobots)

$ErrorActionPreference = 'Stop'

$CollectionName = 'Dwarf Game'
$ProfileName    = 'Dwarf Game'
$SceneName      = 'Game'
$WindowInput    = 'Game Window'
$SoundInput     = 'Game Sound'
$RecordDir      = Join-Path ([Environment]::GetFolderPath('MyVideos')) 'Dwarf Game Recordings'
$LogDir         = Join-Path $env:LOCALAPPDATA 'DwarfGameRecorder'
$LogFile        = Join-Path $LogDir 'recorder.log'
$ObsExe         = Join-Path $env:ProgramFiles 'obs-studio\bin\64bit\obs64.exe'
$WsConfigPath   = Join-Path $env:APPDATA 'obs-studio\plugin_config\obs-websocket\config.json'

New-Item -ItemType Directory -Force -Path $LogDir, $RecordDir | Out-Null

function Log([string]$msg) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class DwarfWin {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    static extern int GetClassName(IntPtr hWnd, StringBuilder name, int max);
    public static string ClassOf(IntPtr hWnd) {
        var sb = new StringBuilder(256);
        GetClassName(hWnd, sb, 256);
        return sb.ToString();
    }
}
"@

# ---------------------------------------------------------------- finding the game

$script:SkipPids = @{}

# A game counts as the owner playing only if a person started it: the desktop icon,
# the Start menu, or Godot's editor (F5). If it was started from a terminal or a script
# (that's how Claude runs the game), it's a robot run. Returns why, or $null for a person.
$ScriptyParents = @('bash.exe', 'sh.exe', 'timeout.exe', 'node.exe', 'claude.exe',
                    'powershell.exe', 'pwsh.exe', 'cmd.exe', 'python.exe', 'conhost.exe')
function Get-RobotReason([int]$procId) {
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$procId"
    if ($proc.CommandLine -match 'autopilot|netcheck|--headless') { return 'robot command' }
    for ($depth = 0; $depth -lt 6 -and $proc; $depth++) {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.ParentProcessId)"
        if (-not $parent) { return $null }
        if ($parent.Name -eq 'explorer.exe') { return $null }          # started by a person
        if ($ScriptyParents -contains $parent.Name.ToLower()) { return "started by $($parent.Name)" }
        $proc = $parent                                                 # e.g. the Godot editor: look further up
    }
    return $null
}

function Find-Game {
    $procs = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ProcessName -like 'Godot*' -or $_.ProcessName -like 'Dwarf*' }
    foreach ($p in $procs) {
        $title = $p.MainWindowTitle
        if (-not $title) { continue }
        if ($title -notlike 'Dwarf Game*') { continue }
        if ($title -like '*Godot Engine*') { continue }   # that's the editor, not the game
        if ($script:SkipPids.ContainsKey($p.Id)) { continue }
        if (-not $IncludeRobots) {
            $why = Get-RobotReason $p.Id
            if ($why) {
                $script:SkipPids[$p.Id] = $true
                Log "Skipping robot run (pid $($p.Id)): $why"
                continue
            }
        }
        return $p
    }
    return $null
}

# OBS window match string: "title:class:exe", with ':' written as '#3A'.
function Obs-WindowString($p) {
    $title = $p.MainWindowTitle.Replace(':', '#3A')
    $class = [DwarfWin]::ClassOf($p.MainWindowHandle).Replace(':', '#3A')
    return "${title}:${class}:$($p.ProcessName).exe"
}

# ---------------------------------------------------------------- OBS remote control

$script:ws = $null
$script:reqId = 0

function Ws-Send($obj) {
    $json = $obj | ConvertTo-Json -Depth 20 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $seg = New-Object 'System.ArraySegment[byte]' -ArgumentList @(,$bytes)
    $script:ws.SendAsync($seg, [Net.WebSockets.WebSocketMessageType]::Text, $true,
        [Threading.CancellationToken]::None).Wait()
}

function Ws-Receive {
    $buf = New-Object byte[] 65536
    $ms = New-Object IO.MemoryStream
    do {
        $seg = New-Object 'System.ArraySegment[byte]' -ArgumentList @(,$buf)
        $task = $script:ws.ReceiveAsync($seg, [Threading.CancellationToken]::None)
        if (-not $task.Wait(20000)) { throw 'OBS stopped answering.' }
        $res = $task.Result
        $ms.Write($buf, 0, $res.Count)
    } while (-not $res.EndOfMessage)
    return ([Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json)
}

function Obs([string]$type, $data = @{}) {
    # Code 207 = "OBS is still starting up / switching": wait and ask again.
    for ($try = 0; $try -lt 120; $try++) {
        $script:reqId++
        $id = "r$($script:reqId)"
        Ws-Send @{ op = 6; d = @{ requestType = $type; requestId = $id; requestData = $data } }
        do { $m = Ws-Receive } until ($m.op -eq 7 -and $m.d.requestId -eq $id)
        $st = $m.d.requestStatus
        if ($st.result) { return $m.d.responseData }
        if ($st.code -ne 207) { throw "OBS said no to ${type}: $($st.comment)" }
        Start-Sleep -Milliseconds 500
    }
    throw "OBS was never ready for $type."
}

function Read-WsConfig { return (Get-Content $WsConfigPath -Raw | ConvertFrom-Json) }

# Turn on OBS's remote control (only possible while OBS is closed, or OBS overwrites it).
function Enable-ObsWebSocket {
    $cfg = Read-WsConfig
    $changed = $false
    if (-not $cfg.server_enabled) { $cfg.server_enabled = $true; $changed = $true }
    if (-not $cfg.server_password) {
        $chars = [char[]]'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
        $cfg.server_password = -join (1..16 | ForEach-Object { $chars | Get-Random })
        $cfg.auth_required = $true
        $changed = $true
    }
    if ($changed) {
        $json = $cfg | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($WsConfigPath, $json, (New-Object Text.UTF8Encoding $false))
        Log 'Turned on OBS remote control (WebSocket).'
    }
}

function Connect-Obs {
    $cfg = Read-WsConfig
    $uri = [Uri]"ws://127.0.0.1:$($cfg.server_port)"
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $script:ws = New-Object Net.WebSockets.ClientWebSocket
            if ($script:ws.ConnectAsync($uri, [Threading.CancellationToken]::None).Wait(3000)) { break }
        } catch { }
        $script:ws = $null
        Start-Sleep -Milliseconds 500
    }
    if (-not $script:ws) { throw 'Could not reach OBS remote control.' }

    $hello = Ws-Receive
    $identify = @{ op = 1; d = @{ rpcVersion = 1; eventSubscriptions = 0 } }
    if ($hello.d.authentication) {
        $sha = [Security.Cryptography.SHA256]::Create()
        $utf = [Text.Encoding]::UTF8
        $secret = [Convert]::ToBase64String($sha.ComputeHash($utf.GetBytes($cfg.server_password + $hello.d.authentication.salt)))
        $identify.d.authentication = [Convert]::ToBase64String($sha.ComputeHash($utf.GetBytes($secret + $hello.d.authentication.challenge)))
    }
    Ws-Send $identify
    $reply = Ws-Receive
    if ($reply.op -ne 2) { throw 'OBS did not accept the password.' }
}

function Disconnect-Obs {
    if ($script:ws) {
        try { $script:ws.CloseAsync([Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'bye', [Threading.CancellationToken]::None).Wait(2000) | Out-Null } catch { }
        $script:ws.Dispose()
        $script:ws = $null
    }
}

function Obs-IsRunning { return [bool](Get-Process obs64 -ErrorAction SilentlyContinue) }

# OBS remembers the last setup it used in user.ini. We save the owner's normal
# setup before starting OBS in the Dwarf Game setup, and put it back afterwards,
# so opening OBS by hand still shows their own scenes.
$UserIni = Join-Path $env:APPDATA 'obs-studio\user.ini'
$RememberKeys = 'Profile', 'ProfileDir', 'SceneCollection', 'SceneCollectionFile', 'ConfigOnNewProfile'

function Save-ObsChoice {
    $saved = @{}
    if (Test-Path $UserIni) {
        foreach ($line in [IO.File]::ReadAllLines($UserIni)) {
            foreach ($k in $RememberKeys) {
                if ($line.StartsWith("$k=")) { $saved[$k] = $line.Substring($k.Length + 1) }
            }
        }
    }
    return $saved
}

function Restore-ObsChoice($saved) {
    if (-not $saved -or $saved.Count -eq 0 -or -not (Test-Path $UserIni)) { return }
    $lines = [IO.File]::ReadAllLines($UserIni)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        foreach ($k in $saved.Keys) {
            if ($lines[$i].StartsWith("$k=")) { $lines[$i] = "$k=$($saved[$k])" }
        }
    }
    [IO.File]::WriteAllLines($UserIni, $lines, (New-Object Text.UTF8Encoding $true))
}

function Setup-Exists {
    $base = Join-Path $env:APPDATA 'obs-studio\basic'
    $dir = $ProfileName.Replace(' ', '_')
    return (Test-Path (Join-Path $base "profiles\$dir")) -and (Test-Path (Join-Path $base "scenes\$dir.json"))
}

function Start-ObsHidden {
    Enable-ObsWebSocket
    $obsArgs = @('--minimize-to-tray', '--disable-shutdown-check', '--disable-updater')
    # Start straight in the Dwarf Game setup. (Switching setups while OBS is
    # still starting up made OBS 32 crash, so we never do that.)
    if (Setup-Exists) { $obsArgs += @('--profile', "`"$ProfileName`"", '--collection', "`"$CollectionName`"") }
    Start-Process -FilePath $ObsExe -WorkingDirectory (Split-Path $ObsExe) -ArgumentList $obsArgs
    Log 'Started OBS (hidden in the tray).'
}

function Close-Obs {
    if (-not (Obs-IsRunning)) { Log 'OBS had already closed.'; return }
    # A polite "please close" first, so OBS saves its settings.
    Start-Process -FilePath taskkill.exe -ArgumentList '/IM', 'obs64.exe' -WindowStyle Hidden -Wait
    for ($i = 0; $i -lt 30; $i++) {
        if (-not (Obs-IsRunning)) { Log 'Closed OBS.'; return }
        Start-Sleep -Milliseconds 500
    }
    Stop-Process -Name obs64 -Force -ErrorAction SilentlyContinue
    Log 'OBS did not close by itself, so it was stopped.'
}

# ---------------------------------------------------------------- one recording

function Use-DwarfSetup {
    $cols = Obs 'GetSceneCollectionList'
    $profs = Obs 'GetProfileList'
    $prev = @{ collection = $cols.currentSceneCollectionName; profile = $profs.currentProfileName }

    if ($profs.profiles -notcontains $ProfileName) {
        Obs 'CreateProfile' @{ profileName = $ProfileName } | Out-Null
    } elseif ($profs.currentProfileName -ne $ProfileName) {
        Obs 'SetCurrentProfile' @{ profileName = $ProfileName } | Out-Null
    }
    if ($cols.sceneCollections -notcontains $CollectionName) {
        Obs 'CreateSceneCollection' @{ sceneCollectionName = $CollectionName } | Out-Null
    } elseif ($cols.currentSceneCollectionName -ne $CollectionName) {
        Obs 'SetCurrentSceneCollection' @{ sceneCollectionName = $CollectionName } | Out-Null
    }
    Start-Sleep -Seconds 2   # OBS needs a moment after switching

    # Recording settings: simple mode, NVIDIA encoder, crash-safe MP4, date/time names.
    $params = @(
        @('Output', 'Mode', 'Simple'),
        @('SimpleOutput', 'RecQuality', 'Small'),
        @('SimpleOutput', 'RecEncoder', 'nvenc'),
        @('SimpleOutput', 'RecFormat2', 'hybrid_mp4'),
        @('SimpleOutput', 'FilePath', $RecordDir),
        @('Output', 'FilenameFormatting', '%CCYY-%MM-%DD %hh-%mm-%ss')
    )
    foreach ($p in $params) {
        Obs 'SetProfileParameter' @{ parameterCategory = $p[0]; parameterName = $p[1]; parameterValue = $p[2] } | Out-Null
    }
    Obs 'SetRecordDirectory' @{ recordDirectory = $RecordDir } | Out-Null
    try {
        Obs 'SetVideoSettings' @{ baseWidth = 1920; baseHeight = 1080; outputWidth = 1920; outputHeight = 1080;
                                  fpsNumerator = 60; fpsDenominator = 1 } | Out-Null
    } catch { Log "Could not set video size (OBS busy?): $_" }

    # Only game sound: mute the desktop audio and microphones in this setup.
    $special = Obs 'GetSpecialInputs'
    foreach ($name in @($special.desktop1, $special.desktop2, $special.mic1, $special.mic2, $special.mic3, $special.mic4)) {
        if ($name) { Obs 'SetInputMute' @{ inputName = $name; inputMuted = $true } | Out-Null }
    }
    return $prev
}

function Point-AtGame($p) {
    $win = Obs-WindowString $p
    $scenes = @((Obs 'GetSceneList').scenes | ForEach-Object { $_.sceneName })
    if ($scenes -notcontains $SceneName) { Obs 'CreateScene' @{ sceneName = $SceneName } | Out-Null }
    Obs 'SetCurrentProgramScene' @{ sceneName = $SceneName } | Out-Null

    $inputs = @((Obs 'GetInputList').inputs | ForEach-Object { $_.inputName })
    # method 2 = Windows Graphics Capture; priority 1 = match the window title exactly.
    $winSettings = @{ window = $win; method = 2; priority = 1; cursor = $false; client_area = $true }
    $sndSettings = @{ window = $win; priority = 1 }
    if ($inputs -contains $WindowInput) {
        Obs 'SetInputSettings' @{ inputName = $WindowInput; inputSettings = $winSettings } | Out-Null
    } else {
        Obs 'CreateInput' @{ sceneName = $SceneName; inputName = $WindowInput; inputKind = 'window_capture'; inputSettings = $winSettings } | Out-Null
    }
    if ($inputs -contains $SoundInput) {
        Obs 'SetInputSettings' @{ inputName = $SoundInput; inputSettings = $sndSettings } | Out-Null
    } else {
        Obs 'CreateInput' @{ sceneName = $SceneName; inputName = $SoundInput; inputKind = 'wasapi_process_output_capture'; inputSettings = $sndSettings } | Out-Null
    }

    # Stretch the game picture to fill the 1920x1080 video (keeping its shape).
    $itemId = (Obs 'GetSceneItemId' @{ sceneName = $SceneName; sourceName = $WindowInput }).sceneItemId
    Obs 'SetSceneItemTransform' @{ sceneName = $SceneName; sceneItemId = $itemId; sceneItemTransform = @{
        positionX = 0; positionY = 0; alignment = 5;
        boundsType = 'OBS_BOUNDS_SCALE_INNER'; boundsAlignment = 0; boundsWidth = 1920; boundsHeight = 1080 } } | Out-Null
    Log "Pointing OBS at: $win"
}

function Record-Session($game) {
    Log "Game found: '$($game.MainWindowTitle)' (pid $($game.Id))."
    $started = Get-Date
    $videoPath = $null
    $startedObs = $false
    $ownerChoice = $null
    $prev = $null

    try {
        if (-not (Obs-IsRunning)) {
            $ownerChoice = Save-ObsChoice
            Start-ObsHidden
            $startedObs = $true
        } elseif (-not (Read-WsConfig).server_enabled) {
            throw 'OBS is already open but its remote control is off. Close OBS once and the next game will record.'
        }

        Connect-Obs
        if ((Obs 'GetRecordStatus').outputActive -or (Obs 'GetStreamStatus').outputActive) {
            throw 'OBS is already recording or streaming; leaving it alone.'
        }
        if ($startedObs) { Start-Sleep -Seconds 4 }   # let OBS finish its first load
        $prev = Use-DwarfSetup
        Point-AtGame $game

        # StartRecord only means "OK, I'll try". Wait until OBS is really recording.
        $recording = $false
        for ($attempt = 1; $attempt -le 3 -and -not $recording -and -not $game.HasExited; $attempt++) {
            Obs 'StartRecord' | Out-Null
            for ($i = 0; $i -lt 20; $i++) {
                if ((Obs 'GetRecordStatus').outputActive) { $recording = $true; break }
                Start-Sleep -Milliseconds 250
            }
            if (-not $recording) { Log "OBS didn't start recording (try $attempt)." }
        }
        if (-not $recording) { throw 'OBS would not start recording.' }
        Log 'Recording started.'

        while (-not $game.HasExited) { Start-Sleep -Milliseconds 500 }

        $out = Obs 'StopRecord'
        for ($i = 0; $i -lt 40; $i++) {
            if (-not (Obs 'GetRecordStatus').outputActive) { break }
            Start-Sleep -Milliseconds 250
        }
        $videoPath = $out.outputPath
        Log "Recording saved: $videoPath"
    }
    catch {
        Log "No video this time: $_"
    }
    finally {
        try {
            if ($startedObs) {
                # We opened OBS, so we close it and put the owner's setup choice back.
                Disconnect-Obs
                Close-Obs
                Restore-ObsChoice $ownerChoice
            } else {
                # The owner had OBS open: switch it back to what they were using.
                if ($prev -and $script:ws) {
                    if ($prev.collection -ne $CollectionName) { Obs 'SetCurrentSceneCollection' @{ sceneCollectionName = $prev.collection } | Out-Null }
                    if ($prev.profile -ne $ProfileName) { Obs 'SetCurrentProfile' @{ profileName = $prev.profile } | Out-Null }
                }
                Disconnect-Obs
            }
        } catch { Log "Problem while tidying up OBS: $_" }
    }

    # Even without a video, the game's log + your feedback are still worth a report.
    while (-not $game.HasExited) { Start-Sleep -Seconds 1 }
    $script:SkipPids[$game.Id] = $true
    try { New-PlaySession $started (Get-Date) $videoPath $game.MainWindowTitle }
    catch { Log "Could not make the session folder: $_" }
}

# ---------------------------------------------------------------- play session folder

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$GameLogFile = Join-Path $env:APPDATA 'Godot\app_userdata\Dwarf Game\logs\godot.log'

# Makes "Dwarf Game Recordings\<date time>\" with the video and the game's log,
# then starts session_report.ps1 (feedback box, snapshots, Claude's report) on its own,
# so the recorder can go straight back to watching.
function New-PlaySession($started, $ended, $videoPath, $title) {
    $name = $started.ToString('yyyy-MM-dd HH-mm-ss')
    $dir = Join-Path $RecordDir $name
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    if ($videoPath -and (Test-Path $videoPath)) {
        Start-Sleep -Seconds 1
        Move-Item -LiteralPath $videoPath -Destination (Join-Path $dir 'video.mp4') -Force
    }
    if ((Test-Path $GameLogFile) -and (Get-Item $GameLogFile).LastWriteTime -ge $started.AddSeconds(-5)) {
        Copy-Item -LiteralPath $GameLogFile -Destination (Join-Path $dir 'game-log.txt') -Force
    }

    $branch = (& git -C $ProjectDir rev-parse --abbrev-ref HEAD 2>$null)
    $commit = (& git -C $ProjectDir rev-parse --short HEAD 2>$null)
    $info = [ordered]@{
        started          = $started.ToString('s')
        ended            = $ended.ToString('s')
        minutes          = [math]::Round(($ended - $started).TotalMinutes, 1)
        window_title     = $title
        git_branch       = "$branch"
        git_commit       = "$commit"
        has_video        = (Test-Path (Join-Path $dir 'video.mp4'))
        has_game_log     = (Test-Path (Join-Path $dir 'game-log.txt'))
    }
    $info | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dir 'session.json') -Encoding UTF8
    Log "Session folder: $dir"

    $reporter = Join-Path $PSScriptRoot 'session_report.ps1'
    Start-Process -FilePath powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-STA', '-File', "`"$reporter`"", '-SessionDir', "`"$dir`"")
}

# ---------------------------------------------------------------- main loop

# When this file is "dot-sourced" (loaded by another script for testing), stop here.
if ($MyInvocation.InvocationName -eq '.') { return }

# Only one recorder at a time.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\DwarfGameAutoRecorder', [ref]$createdNew)
if (-not $createdNew) { Write-Host 'Recorder is already running.'; exit 0 }

if (-not (Test-Path $ObsExe)) { Log "OBS not found at $ObsExe. Recorder stopped."; exit 1 }
Log 'Auto-recorder is watching for the Dwarf Game.'

while ($true) {
    $game = Find-Game
    if ($game) {
        try { Record-Session $game }
        catch { Log "Problem: $_"; $script:SkipPids[$game.Id] = $true }
        if ($Once) { break }
    }
    # Forget skipped games that have closed.
    foreach ($id in @($script:SkipPids.Keys)) {
        if (-not (Get-Process -Id $id -ErrorAction SilentlyContinue)) { $script:SkipPids.Remove($id) }
    }
    Start-Sleep -Seconds 2
}

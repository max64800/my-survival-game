# Puts two icons on the Windows desktop:
#   "Dwarf Game"          - starts the game straight away (no Godot editor)
#   "Dwarf Game Sessions" - opens the folder with play videos, feedback and Claude's reports
# Usage: powershell -ExecutionPolicy Bypass -File tools\make_desktop_shortcuts.ps1

$ErrorActionPreference = 'Stop'
$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Find Godot: the GODOT variable, or the copy winget installed.
$godot = $env:GODOT
if ($godot -and $godot -like '*_console.exe') { $godot = $godot.Replace('_console.exe', '.exe') }
if (-not $godot -or -not (Test-Path $godot)) {
    $godot = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter 'Godot_v4*_win64.exe' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*console*' } | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $godot) { throw 'Could not find Godot. Set the GODOT variable to Godot''s .exe and run this again.' }

$desktop = [Environment]::GetFolderPath('Desktop')
$sessions = Join-Path ([Environment]::GetFolderPath('MyVideos')) 'Dwarf Game Recordings'
New-Item -ItemType Directory -Force -Path $sessions | Out-Null
$shell = New-Object -ComObject WScript.Shell

$game = $shell.CreateShortcut((Join-Path $desktop 'Dwarf Game.lnk'))
$game.TargetPath = $godot
$game.Arguments = "--path `"$ProjectDir`""
$game.WorkingDirectory = $ProjectDir
$game.IconLocation = "$godot,0"
$game.Description = 'Play the Dwarf Game'
$game.Save()

$folder = $shell.CreateShortcut((Join-Path $desktop 'Dwarf Game Sessions.lnk'))
$folder.TargetPath = $sessions
$folder.Description = 'Play videos, your feedback and Claude''s reports'
$folder.Save()

Write-Host "Made 'Dwarf Game' and 'Dwarf Game Sessions' on the desktop."
Write-Host "Game: $godot --path `"$ProjectDir`""

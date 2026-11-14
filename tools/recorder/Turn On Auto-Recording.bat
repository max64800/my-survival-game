@echo off
rem Makes the Dwarf Game auto-recorder start every time Windows starts, and starts it now.
rem It puts a tiny invisible launcher in your Windows "Startup" folder.
setlocal
set "SCRIPT=%~dp0auto_record.ps1"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LAUNCHER=%STARTUP%\Dwarf Game Auto-Recorder.vbs"

> "%LAUNCHER%" echo CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""%SCRIPT%""", 0, False

wscript.exe "%LAUNCHER%"
echo.
echo  Auto-recording is ON.
echo  Every time the Dwarf Game opens, OBS records it.
echo  Videos go to: %USERPROFILE%\Videos\Dwarf Game Recordings
echo.
pause

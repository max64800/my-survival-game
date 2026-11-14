@echo off
rem Stops the Dwarf Game auto-recorder and stops it starting with Windows.
setlocal
set "LAUNCHER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Dwarf Game Auto-Recorder.vbs"
if exist "%LAUNCHER%" del "%LAUNCHER%"
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like '*auto_record.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo.
echo  Auto-recording is OFF.
echo.
pause

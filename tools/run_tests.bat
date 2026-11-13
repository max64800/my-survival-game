@echo off
rem Runs all auto-checks on Windows. Usage: tools\run_tests.bat [only=name]
rem Set GODOT to the full path of Godot's console exe if "godot" isn't a command.
cd /d "%~dp0\.."
if "%GODOT%"=="" set GODOT=godot
"%GODOT%" --headless --path . --import >nul 2>&1
"%GODOT%" --headless --path . --script res://tests/run_tests.gd -- %*
exit /b %ERRORLEVEL%

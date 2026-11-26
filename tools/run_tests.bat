@echo off
rem Runs all auto-checks on Windows. Usage: tools\run_tests.bat [only=name] [fn=name] [verbose=1] [full=1 = also the slow checks]
rem Prints only FAILs + the summary (to save Claude tokens). verbose=1 shows every PASS; set QUIET=0 for raw output.
rem Set GODOT to the full path of Godot's console exe if "godot" isn't a command.
cd /d "%~dp0\.."
if "%GODOT%"=="" set GODOT=godot
"%GODOT%" --headless --path . --import >nul 2>&1
python tools\quiet_run.py "%GODOT%" --headless --audio-driver Dummy --path . --script res://tests/run_tests.gd -- %*
exit /b %ERRORLEVEL%

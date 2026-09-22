@echo off
REM ============================================
REM Install "go2rtc-cam" scheduled task:
REM   - starts at boot
REM   - runs as SYSTEM (no window, background)
REM Must be run As Administrator.
REM
REM After editing config.yaml, run restart.bat to apply.
REM ============================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run this file As Administrator
    echo         (right-click the file - Run as administrator).
    pause
    exit /b 1
)

cd /d %~dp0

if not exist go2rtc.exe (
    echo [ERROR] go2rtc.exe not found in this folder.
    echo         Make sure you copied the whole project folder.
    pause
    exit /b 1
)

REM Use the short (8.3) path for the task, so "/TR" needs no
REM tricky quoting even if this folder contains spaces.
for %%I in ("%~dp0run-hidden.bat") do set "_TASK=%%~sI"
if not defined _TASK set "_TASK=%~dp0run-hidden.bat"

schtasks /Create /TN "go2rtc-cam" /TR "%_TASK%" /SC ONSTART /RU SYSTEM /RL HIGHEST /F
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create the scheduled task.
    pause
    exit /b 1
)

echo Task "go2rtc-cam" created. Starting it now...
schtasks /Run /TN "go2rtc-cam"

echo.
echo This is what the task will run (check it is your run-hidden.bat):
schtasks /Query /TN "go2rtc-cam" /FO LIST /V | findstr /I /C:"Task To Run"
echo.
echo Done. Verify in the browser:
echo Open browser:  http://THIS-SERVER-IP:1984
echo Local test:    http://127.0.0.1:1984
echo.
echo go2rtc now starts at boot and runs hidden - no cmd window.
echo After editing config.yaml: run restart.bat to apply the changes.
echo Logs:  %~dp0logs\go2rtc.log   (view with view-log.bat)
echo Remove later:  run uninstall-autostart.bat
pause
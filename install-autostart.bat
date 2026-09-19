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

schtasks /Create /TN "go2rtc-cam" /TR "\"%~dp0run-hidden.bat\"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create the scheduled task.
    pause
    exit /b 1
)

echo Task "go2rtc-cam" created. Starting it now...
schtasks /Run /TN "go2rtc-cam"

echo.
echo Done. Verify the task:
schtasks /Query /TN "go2rtc-cam" /FO LIST /V | findstr /I /C:"TaskName" /C:"Status" /C:"Task To Run" /C:"Run As User"
echo.
echo Open browser:  http://THIS-SERVER-IP:1984
echo Local test:    http://127.0.0.1:1984
echo.
echo From now on go2rtc starts at boot, runs hidden in the background.
echo After editing config.yaml: run restart.bat to apply the changes.
echo Logs:  %~dp0logs\go2rtc.log
echo Remove later:  run uninstall-autostart.bat
pause
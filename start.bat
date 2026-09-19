@echo off
REM ============================================
REM Manual foreground start of go2rtc (for testing).
REM Safe to re-run: stops any existing go2rtc first,
REM so there is no port conflict, and starts fresh
REM with the current config.yaml.
REM ============================================
cd /d %~dp0

if not exist go2rtc.exe (
    echo [ERROR] go2rtc.exe not found. Make sure you copied the whole project folder.
    pause
    exit /b 1
)

taskkill /f /im go2rtc.exe >nul 2>&1
ping -n 2 127.0.0.1 >nul

echo Starting go2rtc in foreground (press Ctrl+C to stop) ...
echo Each run loads the current config.yaml, so re-run to apply changes.
echo Background mode: use restart.bat (or install autostart).
go2rtc.exe -config config.yaml
@echo off
REM ============================================
REM Start go2rtc in the background - used by the
REM "go2rtc-cam" scheduled task (boot autostart) and
REM by restart.bat to reload the current config.
REM
REM Re-running this script is SAFE: it stops any
REM existing go2rtc first (no port conflict) and
REM starts a fresh one with the current config.yaml.
REM ============================================
cd /d %~dp0

if not exist logs mkdir logs

taskkill /f /im go2rtc.exe >nul 2>&1
ping -n 2 127.0.0.1 >nul

start "go2rtc-cam" /min cmd /c ""%~dp0go2rtc.exe" -config config.yaml >> "%~dp0logs\go2rtc.log" 2>&1"
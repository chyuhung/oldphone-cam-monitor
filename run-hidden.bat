@echo off
REM ============================================
REM Start go2rtc hidden in the background - used by
REM the "go2rtc-cam" scheduled task (boot autostart)
REM and by restart.bat to reload the current config.
REM
REM Re-running this script is SAFE: it stops any
REM existing go2rtc first (no port conflict) and
REM starts a fresh one with the current config.yaml.
REM
REM go2rtc is launched with a HIDDEN window, so it
REM never pops up a cmd window, and closing other
REM windows will not stop it.
REM ============================================
cd /d %~dp0

if not exist logs mkdir logs

taskkill /f /im go2rtc.exe >nul 2>&1
ping -n 2 127.0.0.1 >nul

powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ^
  "Start-Process -FilePath cmd.exe -ArgumentList '/c','go2rtc.exe -config config.yaml >> logs\go2rtc.log 2>&1' -WorkingDirectory '%~dp0' -WindowStyle Hidden"
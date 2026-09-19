@echo off
REM ============================================
REM Stop go2rtc and remove the autostart task.
REM ============================================

cd /d %~dp0

taskkill /f /im go2rtc.exe >nul 2>&1
schtasks /Delete /TN "go2rtc-cam" /F >nul 2>&1

echo.
echo Done. go2rtc is stopped and the autostart task is removed.
pause
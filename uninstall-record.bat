@echo off
REM ============================================
REM Stop the recorder and remove its scheduled task.
REM ============================================

cd /d %~dp0

taskkill /f /im ffmpeg.exe >nul 2>&1
schtasks /Delete /TN "go2rtc-rec" /F >nul 2>&1

echo.
echo Done. Recording stopped and task removed.
pause
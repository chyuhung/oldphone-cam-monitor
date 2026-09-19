@echo off
REM ============================================
REM Restart go2rtc in the background.
REM Use this after editing config.yaml to apply changes.
REM Safe: stops any running go2rtc first, then starts fresh.
REM ============================================
cd /d %~dp0

call "%~dp0run-hidden.bat"

echo.
echo go2rtc restarted in background with the current config.
echo Open browser:  http://THIS-SERVER-IP:1984
echo Local test:    http://127.0.0.1:1984
pause
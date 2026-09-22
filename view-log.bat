@echo off
REM ============================================
REM View the service logs with correct line breaks.
REM Server 2012's old notepad only understands CRLF
REM endings, so go2rtc/ffmpeg logs (LF only) look
REM like one long line there. Use this instead.
REM
REM Usage:  view-log.bat             (logs\go2rtc.log)
REM         view-log.bat rec.log     (logs\rec.log)
REM         view-log.bat rec-ffmpeg.log
REM ============================================
cd /d %~dp0
set "_root=%~dp0"
set "_name=go2rtc.log"
if not "%1"=="" set "_name=%1"
set "_file=%_root%logs\%_name%"

if not exist "%_file%" (
    echo [WARN] %_file% not found yet.
    echo        For go2rtc.log: run install-autostart.bat first.
    echo        For rec.log:     run install-record.bat first.
    echo        Either way, make sure the folder was fully copied.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -LiteralPath '%_file%' -Tail 80"
echo.
pause
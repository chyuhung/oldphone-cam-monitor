@echo off
REM ============================================
REM Install "go2rtc-rec" scheduled task:
REM   - runs at boot, re-checks every 30 minutes
REM   - keeps the recorder alive (restarts ffmpeg if it died)
REM Video is segment-recorded (5-min mp4) into record\.
REM Requires Administrator + vendor\ffmpeg\ffmpeg.exe.
REM ============================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run this file As Administrator
    echo         (right-click the file - Run as administrator).
    pause
    exit /b 1
)

cd /d %~dp0

if not exist "vendor\ffmpeg\ffmpeg.exe" (
    echo [ERROR] vendor\ffmpeg\ffmpeg.exe not found.
    echo         Run download.bat once on an internet PC
    echo         (or fetch ffmpeg.exe from the GitHub Releases page).
    pause
    exit /b 1
)

if not exist "%~dp0rec-loop.bat" (
    echo [ERROR] rec-loop.bat not found in this folder.
    echo         Make sure you copied the WHOLE project folder
    echo         (rec-loop.bat + rec-loop.ps1 must be present).
    pause
    exit /b 1
)
if not exist "%~dp0rec-loop.ps1" (
    echo [ERROR] rec-loop.ps1 not found in this folder.
    echo         Make sure you copied the WHOLE project folder.
    pause
    exit /b 1
)

REM Use the short (8.3) path for the task, so "/TR" needs no
REM tricky quoting even if this folder contains spaces.
for %%I in ("%~dp0rec-loop.bat") do set "_TASK=%%~sI"
if not defined _TASK set "_TASK=%~dp0rec-loop.bat"

schtasks /Create /TN "go2rtc-rec" /TR "%_TASK%" /SC MINUTE /MO 30 /RU SYSTEM /RL HIGHEST /F
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create the scheduled task.
    pause
    exit /b 1
)

echo Task "go2rtc-rec" created. Starting the recorder now...
schtasks /Run /TN "go2rtc-rec"

echo.
echo Also starting the recorder directly (so record\ appears right away)...
call "%~dp0rec-loop.bat"

echo.
echo This is what the task will run (check it is your rec-loop.bat):
schtasks /Query /TN "go2rtc-rec" /FO LIST /V | findstr /I /C:"Task To Run"
echo.
echo Done. Video is being recorded into:  %~dp0record\
echo (one mp4 about every 5 minutes)
echo.
echo Next steps:
echo   1. Install the Tianyi cloud client (cloud.189.cn) and log in.
echo   2. In the client use "Auto Backup" to add the record\ folder.
echo   3. Watch the mp4 files from the Tianyi app on your phone.
echo Remove later:  run uninstall-record.bat
pause
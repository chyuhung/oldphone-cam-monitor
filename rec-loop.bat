@echo off
REM ============================================
REM Start / keep alive the cloud recorder.
REM Runs vendor\ffmpeg\ffmpeg.exe in the background,
REM segment-recording the phone1 stream into record\
REM (5-minute mp4 files).
REM SAFE TO RE-RUN: a lock file keeps only one daemon alive.
REM Used by the "go2rtc-rec" scheduled task every 5 min.
REM ============================================
cd /d %~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rec-loop.ps1"
@echo off
REM ============================================
REM Start / keep alive the cloud recorder.
REM Runs vendor\ffmpeg\ffmpeg.exe in the background,
REM segment-recording the phone1 stream into record\
REM (5-minute mp4 files).
REM SAFE TO RE-RUN: skips if ffmpeg is already recording.
REM Used by the "go2rtc-rec" scheduled task every 30 min.
REM ============================================
cd /d %~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rec-loop.ps1"
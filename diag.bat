@echo off
cd /d "%~dp0"
echo ========================================================================
echo [1] ffmpeg.exe size  ^(gyan=~105MB,  BtbN=~164MB^)
dir vendor\ffmpeg\ffmpeg.exe | findstr /i ffmpeg
echo.
echo [2] ffmpeg version
vendor\ffmpeg\ffmpeg.exe -version 2>nul | findstr /i "ffmpeg version"
if errorlevel 1 echo   ^-^> ffmpeg CANNOT run on this machine
echo.
echo [3] running processes
tasklist | findstr /i "ffmpeg go2rtc"
echo.
echo [4] logs folder
dir logs
echo.
echo [5] manual 12-second test  ^(watch this output carefully^)
for /f "usebackq delims=" %%u in (`powershell -NoProfile -Command "Select-String -Path config.yaml -Pattern 'phone1\s*:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }"`) do set URL=%%u
if "%URL%"=="" (set URL=rtsp://PASTE_YOUR_PHONE1_URL_HERE)
echo test URL = %URL%
vendor\ffmpeg\ffmpeg.exe -hide_banner -rtsp_transport tcp -i "%URL%" -t 12 -c:v copy -c:a aac -b:a 64k test.mp4
echo ffmpeg exit code = %errorlevel%
if exist test.mp4 (dir /a-d test.mp4) else (echo NO test.mp4 was created)
echo ========================================================================
pause
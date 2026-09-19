@echo off
REM ============================================
REM Binary fetch tool - run after cloning from GitHub.
REM The git repo intentionally does NOT store binaries.
REM This script downloads them from official sources:
REM   - go2rtc.exe                  (project root)
REM   - vendor\ZeroTier One 1.6.6.msi  (remote access only)
REM Run once on any internet-enabled PC to build the
REM complete offline package, then copy the whole
REM folder to the Win2012 server (no internet needed).
REM ============================================
cd /d %~dp0

echo.
echo [1/2] go2rtc.exe ...
if exist go2rtc.exe (
    echo   already present, skip.
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
      "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
      "$u='https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_win64.zip';" ^
      "$z='go2rtc_win64.zip';" ^
      "try { $wc=New-Object System.Net.WebClient; $wc.DownloadFile($u,$z); $wc.Dispose() } catch { Write-Host '[ERROR] go2rtc download failed/timeout'; Write-Host '  get go2rtc_win64.zip from the GitHub Releases page and extract it here'; exit 1 };" ^
      "Expand-Archive -Path $z -DestinationPath . -Force; Remove-Item $z;" ^
      "Write-Host '   OK: go2rtc.exe ready'"
)

echo.
echo [2/2] ZeroTier One 1.6.6.msi (only needed for remote access) ...
if not exist vendor mkdir vendor
if exist "vendor\ZeroTier One 1.6.6.msi" (
    echo   already present, skip.
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
      "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
      "$u='https://download.zerotier.com/RELEASES/1.6.6/dist/ZeroTier%%20One.msi';" ^
      "$o=Join-Path 'vendor' 'ZeroTier One 1.6.6.msi';" ^
      "try { $wc=New-Object System.Net.WebClient; $wc.DownloadFile($u,$o); $wc.Dispose() } catch { Write-Host '[ERROR] ZeroTier download failed/timeout'; Write-Host '  this file only matters if you want remote access, skip it if you cannot'; exit 1 };" ^
      "Write-Host '   OK: ZeroTier One 1.6.6.msi ready'"
)

echo.
echo All binaries ready. Copy this whole folder to the Win2012 server.
pause
# go2rtc-cam stream recorder (called by rec-loop.bat / scheduled task)
# Continuously records the phone1 stream from config.yaml into record\
# as 5-minute mp4 segments (safe to read for a cloud auto-backup tool).
# SAFE TO RE-RUN: if ffmpeg is already recording, this script exits.
# Errors are written to logs\rec.log so failures are easy to inspect.

$ErrorActionPreference = 'Stop'

$dir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfg    = Join-Path $dir 'config.yaml'
$ffmpeg = Join-Path $dir 'vendor\ffmpeg\ffmpeg.exe'
$recDir = Join-Path $dir 'record'
$logDir = Join-Path $dir 'logs'
$log    = Join-Path $logDir 'rec.log'
$ffLog  = Join-Path $logDir 'rec-ffmpeg.log'

function Write-RecLog([string]$msg) {
    Add-Content -Path $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg)
}

try {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }

    if (-not (Test-Path $ffmpeg)) {
        Write-RecLog 'ERROR: vendor\ffmpeg\ffmpeg.exe not found (run download.bat once)'
        exit 1
    }

    $url = $null
    foreach ($line in [System.IO.File]::ReadAllLines($cfg)) {
        if ($line -match '^\s*phone1:\s*(rtsp://\S+)') {
            $url = $Matches[1]
            break
        }
    }
    if (-not $url) {
        Write-RecLog 'ERROR: streams.phone1 not found in config.yaml - edit config.yaml first'
        exit 1
    }

    # already recording? nothing to do (keep-alive from a scheduled task)
    if (Get-Process ffmpeg -ErrorAction SilentlyContinue) {
        exit 0
    }

    # drop leftover zero-byte segments (e.g. after a crash)
    Get-ChildItem -Path $recDir -Filter *.mp4 -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -eq 0 } | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-RecLog ('recorder start, url=' + $url)

    Start-Process -FilePath $ffmpeg `
        -ArgumentList @(
            '-hide_banner', '-loglevel', 'error', '-nostdin',
            '-rtsp_transport', 'tcp',
            '-i', $url,
            '-c', 'copy',
            '-f', 'segment', '-segment_time', '300', '-reset_timestamps', '1',
            '-strftime', '1',
            (Join-Path $recDir '%Y%m%d_%H%M%S.mp4')
        ) `
        -WindowStyle Hidden `
        -RedirectStandardError $ffLog

    exit 0
}
catch {
    Write-RecLog ('ERROR: ' + $_.Exception.Message)
    exit 1
}
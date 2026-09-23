# go2rtc-cam recorder DAEMON (called by rec-loop.bat / scheduled task every 5 min)
# SAFE TO RE-RUN: a lock file keeps only one daemon alive (others exit 0).
# SELF-HEALING: every 15s it checks for a fresh mp4 segment;
#   if none appears for >360s, the hung ffmpeg is killed and restarted,
#   and if the ffmpeg process dies it is started again.
# It only ever manages ffmpeg processes whose command line contains the
# segment name template %Y%m%d (i.e. its own recorder), so other ffmpeg
# instances on the machine are never touched.
# Errors / events are appended to logs\rec.log for easy inspection.

$ErrorActionPreference = 'Stop'

$dir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfg    = Join-Path $dir 'config.yaml'
$ffmpeg = Join-Path $dir 'vendor\ffmpeg\ffmpeg.exe'
$recDir = Join-Path $dir 'record'
$logDir = Join-Path $dir 'logs'
$log    = Join-Path $logDir 'rec.log'
$ffLog  = Join-Path $logDir 'rec-ffmpeg.log'
$lock   = Join-Path $logDir 'rec-loop.lock'

$maxHangSec = 360    # recorder idle longer than this => kill + restart
$segmentSec = 300    # mp4 segment length in seconds
$boot       = Get-Date

function Write-RecLog([string]$msg) {
    Add-Content -Path $log -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg)
}

function Get-PhoneUrl {
    foreach ($line in [System.IO.File]::ReadAllLines($cfg)) {
        if ($line -match '^\s*phone1:\s*(rtsp://\S+)') { return $Matches[1] }
    }
    return $null
}

# Find OUR recorder ffmpeg by its segment name template in the command line.
# Formats such as a rec-loop daemon would start. Null if not running.
function Get-MyFfmpeg {
    $list = $null
    try {
        $list = Get-CimInstance Win32_Process -Filter "Name='ffmpeg.exe'" -ErrorAction SilentlyContinue
    } catch {
        try {
            $list = Get-WmiObject Win32_Process -Filter "Name='ffmpeg.exe'" -ErrorAction SilentlyContinue
        } catch { }
    }
    if (-not $list) { return $null }
    foreach ($p in (@($list))) {
        if ($p.CommandLine -and ($p.CommandLine -match '%Y%m%d_%H%M%S\.mp4')) {
            return [pscustomobject]@{ Id = [int]$p.ProcessId }
        }
    }
    return $null
}

try {
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }

    if (-not (Test-Path $ffmpeg)) {
        Write-RecLog 'ERROR: vendor\ffmpeg\ffmpeg.exe not found (run download.bat once)'
        exit 1
    }

    $url = Get-PhoneUrl
    if (-not $url) {
        Write-RecLog 'ERROR: streams.phone1 not found in config.yaml - edit config.yaml first'
        exit 1
    }

    # single-instance lock: only one daemon at a time (scheduled task may fire often)
    $fs = $null
    try {
        $fs = [System.IO.File]::Open($lock, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    } catch {
        exit 0   # another recorder daemon is already running
    }

    try {
        $fails = 0
        $sleep = 15

        while ($true) {
            $my = Get-MyFfmpeg

            if ($my) {
                $newest = Get-ChildItem -Path $recDir -Filter *.mp4 -ErrorAction SilentlyContinue |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
                $base = if ($newest) { $newest.LastWriteTime } else { $boot }
                $idle = (Get-Date) - $base

                if ($idle.TotalSeconds -gt $maxHangSec) {
                    Write-RecLog ('WARNING: recorder idle for {0}s - killing hung ffmpeg (pid {1}) and restarting' -f [int]$idle.TotalSeconds, $my.Id)
                    Stop-Process -Id $my.Id -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                    continue
                }

                Start-Sleep -Seconds $sleep
                continue
            }

            # our recorder is not running -> (re)start it
            $boot = Get-Date
            Write-RecLog ('recorder start, url=' + $url)
            try {
                $p = Start-Process -FilePath $ffmpeg `
                    -ArgumentList @(
                        '-hide_banner', '-loglevel', 'error', '-nostdin',
                        '-rtsp_transport', 'tcp',
                        '-i', $url,
                        '-c:v', 'copy', '-c:a', 'aac', '-b:a', '64k',
                        '-f', 'segment', '-segment_time', ([string]$segmentSec),
                        '-reset_timestamps', '1', '-strftime', '1',
                        (Join-Path $recDir '%Y%m%d_%H%M%S.mp4')
                    ) `
                    -WindowStyle Hidden `
                    -RedirectStandardError $ffLog `
                    -PassThru
            } catch {
                Write-RecLog ('ERROR: cannot start ffmpeg: ' + $_.Exception.Message)
                $fails++
                if ($fails -ge 3) { Write-RecLog 'ERROR: giving up for 5 minutes (check camera / config)'; Start-Sleep -Seconds 300; $fails = 0 }
                Start-Sleep -Seconds $sleep
                continue
            }

            Start-Sleep -Seconds 2
            if ($p.HasExited) {
                $msg = 'ffmpeg exited immediately (code ' + $p.ExitCode + '). See logs\rec-ffmpeg.log'
                try {
                    $tail = (Get-Content -Path $ffLog -Tail 5 -ErrorAction SilentlyContinue) -join ' | '
                    if ($tail) { $msg = $msg + '  ->  ' + $tail }
                } catch { }
                Write-RecLog ('ERROR: ' + $msg)
                $fails++
                if ($fails -ge 3) { Write-RecLog 'ERROR: giving up for 5 minutes (check camera / config)'; Start-Sleep -Seconds 300; $fails = 0 }
                Start-Sleep -Seconds $sleep
                continue
            }

            $fails = 0
            Start-Sleep -Seconds $sleep
        }
    } finally {
        if ($fs) { $fs.Close() }
        Remove-Item -Path $lock -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-RecLog ('ERROR: ' + $_.Exception.Message)
    exit 1
}
# Mechanic Miner Save Watcher

$base = "$env:APPDATA\mechanicminer"
$tmp = "$base\tmp"
$storytime = "$base\games\Storytime"
$checkpoint = "$storytime\checkpoint"

New-Item -ItemType Directory -Path $storytime -Force | Out-Null
New-Item -ItemType Directory -Path $checkpoint -Force | Out-Null

Write-Host "========================================="
Write-Host "Phase 1: Restoring .mm files for 5 minutes"
Write-Host "Launch the game NOW, then load your save"
Write-Host "========================================="
Write-Host ""

$startTime = Get-Date
$count = 0

while ((Get-Date) - $startTime -lt [TimeSpan]::FromMinutes(5)) {
    $mmFiles = Get-ChildItem -Path $storytime -Filter "*.mm" -File -ErrorAction SilentlyContinue
    foreach ($file in $mmFiles) {
        $dest = Join-Path $tmp $file.Name
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $file.FullName -Destination $tmp -Force
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Restored $($file.Name) to tmp"
            $count++
        }
    }
    Start-Sleep -Milliseconds 200
}

Write-Host ""
if ($count -eq 0) {
    Write-Host "WARNING: No .mm files were ever restored. It might be empty."
} else {
    Write-Host "Restored $count file(s) during Phase 1."
}
Write-Host ""
Write-Host "========================================="
Write-Host "Phase 2: Watching for saves"
Write-Host "========================================="
Write-Host ""

$lastTimes = @{}

while ($true) {
    $files = Get-ChildItem -Path $tmp -File -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $modTime = $file.LastWriteTime

        if (-not $lastTimes.ContainsKey($file.Name) -or $lastTimes[$file.Name] -ne $modTime) {
            Start-Sleep -Milliseconds 500

            $file = Get-Item "$tmp\$($file.Name)" -ErrorAction SilentlyContinue
            if ($null -eq $file) { continue }

            try {
                Copy-Item -Path $file.FullName -Destination $storytime -Force
                Copy-Item -Path $file.FullName -Destination $checkpoint -Force
                $lastTimes[$file.Name] = $file.LastWriteTime
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Copied $($file.Name)"
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR copying $($file.Name): $_"
            }
        }
    }

    Start-Sleep -Milliseconds 1000
}

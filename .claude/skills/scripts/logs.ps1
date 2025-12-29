param(
    [int]$l = 20,
    [string]$only = ""
)

$logPath = "$env:USERPROFILE\Documents\Assetto Corsa\logs\custom_shaders_patch.log"

$lines = Get-Content $logPath -Tail 5000 | Select-String 'ac-tracer/'

if ($only -eq "ERROR") {
    $lines = $lines | Select-String 'ERROR'
} elseif ($only -eq "WARN") {
    $lines = $lines | Select-String 'WARN'
}

$result = $lines | Select-Object -Last $l

if ($result) {
    $result
} else {
    Write-Host "No ac-tracer log entries found"
}

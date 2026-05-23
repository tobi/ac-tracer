param(
    [int]$l = 20,
    [ValidateSet("", "ERROR", "WARN", "PERF", "DEBUG")]
    [string]$only = "",
    [string]$app = "ac-tracer",
    [int]$tail = 5000
)

$logPath = "$env:USERPROFILE\Documents\Assetto Corsa\logs\custom_shaders_patch.log"

if (-not (Test-Path $logPath)) {
    Write-Error "CSP log not found: $logPath"
    exit 1
}

$pattern = [regex]::Escape($app) + '/'
$lines = Get-Content $logPath -Tail $tail | Select-String $pattern

if ($only -ne "") {
    $lines = $lines | Select-String $only
}

$result = $lines | Select-Object -Last $l

if ($result) {
    $result
} else {
    Write-Host "No $app log entries found"
}

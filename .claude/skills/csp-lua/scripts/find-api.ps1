param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Query,

    [int]$Context = 2,
    [int]$Max = 80,
    [switch]$SdkOnly
)

$skillRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$referenceRoot = Join-Path $skillRoot 'reference'

if ($SdkOnly) {
    $targets = @(Join-Path $referenceRoot 'sdk')
} else {
    $targets = @(
        (Join-Path $referenceRoot 'lib.lua'),
        (Join-Path $referenceRoot 'sdk')
    )
}

$rg = Get-Command rg -ErrorAction SilentlyContinue
if ($rg) {
    & rg -n -C $Context --max-count $Max --fixed-strings -- $Query @targets
    exit $LASTEXITCODE
}

$matches = Select-String -Path $targets -Pattern ([regex]::Escape($Query)) -Recurse -Context $Context -ErrorAction SilentlyContinue |
    Select-Object -First $Max

if ($matches) {
    $matches
} else {
    Write-Host "No matches found for '$Query'"
}

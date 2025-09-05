param(
  [int]$Port = 8000
)
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Host "Serving $Root at http://localhost:$Port"
Set-Location $Root
python -m http.server $Port

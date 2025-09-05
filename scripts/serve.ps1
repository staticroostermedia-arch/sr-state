param([int]$Port=8000)
$dist = Join-Path $PSScriptRoot '..' | Join-Path 'dist'
Start-Process powershell -ArgumentList "-NoExit","-Command","cd `"$dist`"; python -m http.server $Port"
Start-Process "http://localhost:$Port/index.html"

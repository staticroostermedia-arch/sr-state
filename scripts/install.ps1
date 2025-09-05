param(
  [int]$Port = 8000,
  [string]$RepoUrl = ""
)
$ErrorActionPreference = "Stop"
$AppName = "static-rooster"
$InstallDir = Join-Path $env:USERPROFILE $AppName
Write-Host "[*] Installing to $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
# Copy payload (assumes script is inside the bundle)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundleDir = Join-Path $ScriptDir ".."
Copy-Item -Recurse -Force -Path (Join-Path $BundleDir "*") -Destination $InstallDir -Exclude "dist",".git"

# Build
Push-Location $InstallDir
if (Test-Path "scripts\build.sh") {
  bash scripts/build.sh
}

# Start simple server (user can later make a service with NSSM or Task Scheduler)
Push-Location "dist"
$py = "python"
$proc = Start-Process -PassThru -FilePath $py -ArgumentList "-m http.server $Port"
Pop-Location
Write-Host "[*] Server started on port $Port (PID $($proc.Id))"

# Git init/push
if (-not (Test-Path ".git")) {
  git init | Out-Null
  git branch -M main
}
git add -A
git commit -m "Initial import via installer" | Out-Null
if ($RepoUrl -ne "") {
  if (git remote | Select-String -SimpleMatch "origin") {
    git remote set-url origin $RepoUrl
  } else {
    git remote add origin $RepoUrl
  }
  git push -u origin main
  Write-Host "[*] Pushed to $RepoUrl"
} else {
  Write-Host "[*] No RepoUrl provided; repository initialized locally."
}
Write-Host "=== Installation Complete ==="
Write-Host "Open: http://localhost:$Port/"

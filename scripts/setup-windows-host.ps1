# Eski script - install-windows.ps1 kullan.
param(
  [string]$RepoUrl = "",
  [string]$TargetDir = "",
  [switch]$Force
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$install = Join-Path $scriptDir "install-windows.ps1"

if (-not $TargetDir) {
  $TargetDir = Split-Path -Parent $scriptDir
}

& $install -InstallDir $TargetDir -Force:$Force

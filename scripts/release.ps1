# ClearDay release helper
# Bumps the Play versionCode (+N in pubspec.yaml), then builds a signed AAB.
#
# Usage (from project root):
#   .\scripts\release.ps1
#   .\scripts\release.ps1 -BumpName   # also bumps patch: 1.0.0 -> 1.0.1
#   .\scripts\release.ps1 -SkipBuild  # only bump version, don't build

param(
  [switch]$BumpName,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$pubspecPath = Join-Path $root "pubspec.yaml"
$pubspec = Get-Content $pubspecPath -Raw

if ($pubspec -notmatch '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$') {
  throw "Could not find version like 1.0.0+1 in pubspec.yaml"
}

$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]
$build = [int]$Matches[4]

$oldVersion = "$major.$minor.$patch+$build"

if ($BumpName) {
  $patch++
}
$build++

$newVersion = "$major.$minor.$patch+$build"
$pubspec = [regex]::Replace(
  $pubspec,
  '(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$',
  "version: $newVersion"
)
Set-Content -Path $pubspecPath -Value $pubspec -NoNewline -Encoding utf8

Write-Host "Version: $oldVersion -> $newVersion" -ForegroundColor Cyan
Write-Host "  versionName = $major.$minor.$patch"
Write-Host "  versionCode = $build"

if ($SkipBuild) {
  Write-Host "Skipped build (-SkipBuild)." -ForegroundColor Yellow
  exit 0
}

Write-Host "`nBuilding release app bundle..." -ForegroundColor Cyan
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
  throw "flutter build appbundle failed"
}

$aab = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"
Write-Host "`nDone." -ForegroundColor Green
Write-Host "Upload this file to Play Console:"
Write-Host $aab

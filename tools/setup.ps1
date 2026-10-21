<#
.SYNOPSIS
    One-command setup for a fresh clone of Fiel al Libro.

.DESCRIPTION
    Checks the machine, installs the missing pieces that can be installed
    automatically, and prints what still needs a human.

    Run from the repository root:
      powershell -ExecutionPolicy Bypass -File tools\setup.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\setup.ps1 -InstallTools
#>

[CmdletBinding()]
param(
    [switch] $InstallTools
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Section($title) {
    $pad = [Math]::Max(0, 58 - $title.Length)
    Write-Host ""
    Write-Host "-- $title " -ForegroundColor Cyan -NoNewline
    Write-Host ("-" * $pad) -ForegroundColor DarkCyan
}

function Ok($msg)   { Write-Host "  [ok] " -ForegroundColor Green  -NoNewline; Write-Host $msg }
function Warn($msg) { Write-Host "  [!!] " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Bad($msg)  { Write-Host "  [XX] " -ForegroundColor Red    -NoNewline; Write-Host $msg }

Section "Tools"

if (Get-Command git -ErrorAction SilentlyContinue) { Ok ("git " + (git --version | Select-Object -First 1)) } else { Bad "git not found" }
if (Get-Command gh   -ErrorAction SilentlyContinue) { Ok "GitHub CLI present" } else { Warn "GitHub CLI not found (optional: only needed to create the remote)" }

$lfs = git lfs version 2>$null
if ($lfs) { Ok "git-lfs installed" } else { Warn "git-lfs not installed - run: git lfs install" }

Section "Godot"

$godot = & (Join-Path $PSScriptRoot 'godot.ps1') --version 2>$null | Select-Object -First 1
if ($godot) {
    Ok ("Godot " + $godot)
} else {
    Bad "Godot 4 not found"
    if ($InstallTools) {
        Write-Host "    installing via winget..."
        winget install --id GodotEngine.GodotEngine -e --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
    } else {
        Write-Host "    run with -InstallTools to install it automatically"
    }
}

Section "Blender"

# Blender builds the hero rigs and their animation sets (GDD.md §15.3).
# It is NOT needed to play or to build the game, so a missing one is a
# warning and not a failure.
$blender = & (Join-Path $PSScriptRoot 'blender.ps1') --version 2>$null |
           Select-String -Pattern 'Blender \d' | Select-Object -First 1
if ($blender) {
    Ok ($blender.ToString().Trim())
} else {
    Warn "Blender not found - the rigs and the animation sets need it"
    if ($InstallTools) {
        Write-Host "    installing via winget..."
        winget install --id BlenderFoundation.Blender -e --accept-package-agreements --accept-source-agreements --silent --disable-interactivity
    } else {
        Write-Host "    run with -InstallTools to install it automatically"
    }
}

# Export templates: ~1.2 GB, and the local build step needs them.
$templateDir = Join-Path $env:APPDATA 'Godot\export_templates'
$hasTemplates = $false
if (Test-Path $templateDir) {
    $version = Get-ChildItem $templateDir -Directory -ErrorAction SilentlyContinue |
               Where-Object { Test-Path (Join-Path $_.FullName 'windows_release_x86_64.exe') } |
               Select-Object -First 1
    if ($version) { $hasTemplates = $true; Ok ("export templates installed (" + $version.Name + ")") }
}
if (-not $hasTemplates) {
    Warn "export templates missing - the local build step will fail"
    Write-Host "    Godot editor -> Editor -> Manage Export Templates... -> 4.7.2-stable -> Download and Install"
    Write-Host "    (or unzip Godot_v4.7.2-stable_export_templates.tpz into %APPDATA%\Godot\export_templates\4.7.2.stable\)"
}

Section "First import"
& (Join-Path $PSScriptRoot 'godot.ps1') --headless --editor --quit | Out-Null
Ok "project imported"

Section "Tests"
& (Join-Path $PSScriptRoot 'godot.ps1') --headless res://tests/test_runner.tscn
if ($LASTEXITCODE -eq 0) { Ok "all tests green" } else { Bad ("tests FAILED (exit " + $LASTEXITCODE + ")") }

Section "Remaining manual steps"
Write-Host "  1. Steam Direct application      - https://partner.steamgames.com/ (USD 100)"
Write-Host "  2. Manual trademark searches     - see docs\IP_CLEARANCE.md (private, on the owner's machine)"
Write-Host "  3. File the EUIPO composite mark - 'FIEL AL LIBRO: LA LOCURA Y LA VERDAD', classes 9 + 41"
Write-Host "  4. Set up monthly cloud backup   - 3-2-1: GitHub + local external + monthly archive"
Write-Host ""

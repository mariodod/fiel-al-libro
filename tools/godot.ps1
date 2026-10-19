<#
.SYNOPSIS
    Finds the Godot 4 executable and forwards all arguments to it.

.DESCRIPTION
    Godot is installed via winget, which may or may not have put it on PATH
    (winget can only create command-line aliases with administrator
    privileges). This script locates the binary wherever it actually is so
    that every command in the docs works verbatim.

    Search order:
      1. $env:GODOT_BIN           (explicit override, if set)
      2. godot / godot4 on PATH
      3. The winget package folder
      4. Program Files
      5. The user's local app data

.EXAMPLE
    .\tools\godot.ps1 --headless res://tests/test_runner.tscn
    .\tools\godot.ps1 --headless --export-release "Windows Desktop" build/FielAlLibro.exe
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $GodotArgs
)

$ErrorActionPreference = 'Stop'

function Find-Godot {
    if ($env:GODOT_BIN -and (Test-Path $env:GODOT_BIN)) {
        return $env:GODOT_BIN
    }

    # 1. On PATH.
    foreach ($name in @('godot', 'godot4')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }

    # 2. winget package folder.
    $winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $winget) {
        $hit = Get-ChildItem $winget -Filter 'Godot_v*_console.exe' -Recurse -ErrorAction SilentlyContinue |
               Sort-Object FullName -Descending | Select-Object -First 1
        if ($hit) { return $hit.FullName }
        $hit = Get-ChildItem $winget -Filter 'Godot_v*.exe' -Recurse -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -notmatch 'console' } |
               Sort-Object FullName -Descending | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }

    # 3. Program Files / local app data.
    foreach ($dir in @(
        (Join-Path $env:ProgramFiles 'Godot'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Godot'),
        (Join-Path $env:LOCALAPPDATA 'Godot')
    )) {
        if (Test-Path $dir) {
            $hit = Get-ChildItem $dir -Filter 'Godot*.exe' -Recurse -ErrorAction SilentlyContinue |
                   Sort-Object FullName -Descending | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }

    return $null
}

$godot = Find-Godot
if (-not $godot) {
    Write-Error @"
Godot 4 was not found.

Install it with:
  winget install --id GodotEngine.GodotEngine -e --accept-package-agreements --accept-source-agreements

Or set the path explicitly:
  `$env:GODOT_BIN = 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
"@
    exit 1
}

Write-Host "[godot] $godot" -ForegroundColor DarkGray

# Godot writes warnings and errors to stderr even when the run SUCCEEDS,
# and PowerShell turns native stderr into a terminating error when
# $ErrorActionPreference is 'Stop'. The result: a green test run reports
# itself as a failure, and setup.ps1 tells the owner their build is broken.
#
# Merge the streams, do not stop on them, and trust the exit code — it is
# the only thing that says whether the run actually worked.
$ErrorActionPreference = 'Continue'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
& $godot @GodotArgs 2>&1 | ForEach-Object { "$_" }
exit $LASTEXITCODE

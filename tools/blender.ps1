<#
.SYNOPSIS
    Finds the Blender executable and forwards all arguments to it.

.DESCRIPTION
    Blender is installed via winget, which may or may not have put it on PATH
    (winget can only create command-line aliases with administrator
    privileges). This script locates the binary wherever it actually is so
    that every command in the docs works verbatim.

    Search order:
      1. $env:BLENDER_BIN         (explicit override, if set)
      2. blender on PATH
      3. The winget package folder
      4. Program Files / local app data

    Blender is used for the hero rigs and their animation sets (GDD.md §15.3):
    low-poly meshes, hand-painted textures, glTF out. The scripts that build
    them are run headless, so every command below is a batch job.

.EXAMPLE
    .\tools\blender.ps1 --version
    .\tools\blender.ps1 -b --factory-startup -P tools\build_animations.py -- --out assets\models
#>

$BlenderArgs = $args

$ErrorActionPreference = 'Stop'

# The project root: this script's directory's parent.
#
# Blender resolves relative paths against the CURRENT WORKING DIRECTORY, and
# a script that writes into assets\ has to write into THIS repository, not
# into wherever the command was typed.
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

# `--out <dir>` is read HERE, not by Blender.
#
# Blender's own command-line parser treats the first argument after `--` as
# a FILE to open. Pass `--out assets\models` through to Blender and the run
# ends with "unknown argument, loading as file: --out" and a non-zero exit
# code, after a build that actually worked. So the wrapper takes the
# argument, puts the directory in the environment, and hands Blender only
# the flags that are Blender's.
$BlenderArgs = @()
$outDir = $env:FIEL_MODELS_OUT
$i = 0
while ($i -lt $args.Count) {
    $arg = $args[$i]
    if ($arg -eq '--out' -and ($i + 1) -lt $args.Count) {
        $outDir = $args[$i + 1]
        $i += 2
        continue
    }
    if ($arg -like '--out=*') {
        $outDir = $arg.Substring(6)
        $i += 1
        continue
    }
    $BlenderArgs += $arg
    $i += 1
}
if ($outDir) {
    $env:FIEL_MODELS_OUT = $outDir
}

function Find-Blender {
    if ($env:BLENDER_BIN -and (Test-Path $env:BLENDER_BIN)) {
        return $env:BLENDER_BIN
    }

    # 1. On PATH.
    $cmd = Get-Command 'blender' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2. winget package folder.
    $winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $winget) {
        $hit = Get-ChildItem $winget -Filter 'blender.exe' -Recurse -ErrorAction SilentlyContinue |
               Sort-Object FullName -Descending | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }

    # 3. Program Files / local app data.
    foreach ($dir in @(
        (Join-Path $env:ProgramFiles 'Blender Foundation'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Blender Foundation'),
        (Join-Path $env:LOCALAPPDATA 'Blender Foundation')
    )) {
        if (Test-Path $dir) {
            $hit = Get-ChildItem $dir -Filter 'blender.exe' -Recurse -ErrorAction SilentlyContinue |
                   Sort-Object FullName -Descending | Select-Object -First 1
            if ($hit) { return $hit.FullName }
        }
    }

    return $null
}

$blender = Find-Blender
if (-not $blender) {
    Write-Error @"
Blender was not found.

Install it with:
  winget install --id BlenderFoundation.Blender -e --accept-package-agreements --accept-source-agreements

Or set the path explicitly:
  `$env:BLENDER_BIN = 'C:\path\to\blender.exe'
"@
    exit 1
}

if ($BlenderArgs.Count -eq 0) {
    Write-Host ""
    Write-Host "  Usage:" -ForegroundColor Cyan
    Write-Host "    .\tools\blender.ps1 --version                              the version"
    Write-Host "    .\tools\blender.ps1 -b -P <script.py>                     run a script headless"
    Write-Host "    .\tools\blender.ps1 -b -P <script.py> -- --out <dir>     ...and tell it where to write"
    Write-Host ""
    exit 0
}

Write-Host "[blender] $blender" -ForegroundColor DarkGray
Write-Host "[project] $repoRoot" -ForegroundColor DarkGray

# Blender writes warnings and errors to stderr even when the run SUCCEEDS,
# and PowerShell turns native stderr into a terminating error when
# $ErrorActionPreference is 'Stop'. The result: a good build reports itself
# as a failure.
#
# Merge the streams, do not stop on them, and trust the exit code — it is
# the only thing that says whether the run actually worked.
$ErrorActionPreference = 'Continue'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
& $blender @BlenderArgs 2>&1 | ForEach-Object { "$_" }
exit $LASTEXITCODE

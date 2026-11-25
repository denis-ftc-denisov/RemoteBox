<#
  Sets up an MSYS2 UCRT64 build environment for the native Windows build of
  RemoteBox. Safe to re-run: an existing MSYS2 installation is reused and only
  missing packages and Perl modules are installed.

  Usage (from any PowerShell prompt, admin rights are not needed):
      powershell -ExecutionPolicy Bypass -File misc\windows\setup-msys2.ps1 [-Msys2Root C:\msys64]
#>
param(
    [string]$Msys2Root = 'C:\msys64'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bash = Join-Path $Msys2Root 'usr\bin\bash.exe'

function Invoke-Msys2([string]$cmd) {
    $env:MSYSTEM = 'UCRT64'
    $env:CHERE_INVOKING = '1'
    & $bash -lc $cmd
    if ($LASTEXITCODE -ne 0) { throw "MSYS2 command failed ($LASTEXITCODE): $cmd" }
}

if (-not (Test-Path $bash)) {
    # The base archive extracts to <parent>\msys64, so the root must be named msys64
    if ((Split-Path -Leaf $Msys2Root) -ne 'msys64') { throw "Msys2Root must end in 'msys64'" }
    $parent = Split-Path -Parent $Msys2Root
    $sfx = Join-Path $env:TEMP 'msys2-base-x86_64-latest.sfx.exe'
    Write-Host "Downloading MSYS2 base archive..."
    # curl.exe ships with Windows 10 1803+ and is far more reliable than Invoke-WebRequest
    & curl.exe -fL --retry 5 --retry-delay 3 -o $sfx `
        'https://github.com/msys2/msys2-installer/releases/latest/download/msys2-base-x86_64-latest.sfx.exe'
    if ($LASTEXITCODE -ne 0) { throw "Download of MSYS2 failed ($LASTEXITCODE)" }
    Write-Host "Extracting MSYS2 to $Msys2Root..."
    & $sfx -y "-o$parent"
    if ($LASTEXITCODE -ne 0) { throw "MSYS2 extraction failed ($LASTEXITCODE)" }
    if (-not (Test-Path $bash)) { throw "MSYS2 extraction failed" }
    Remove-Item $sfx

    # First login initialises the keyring and home directory
    Invoke-Msys2 'true'
}

# Full system upgrade. Core packages may require the shell to restart, hence twice.
Invoke-Msys2 'pacman -Syuu --noconfirm'
Invoke-Msys2 'pacman -Syuu --noconfirm'

# Windows PowerShell mangles embedded double quotes passed to native commands,
# so convert to an MSYS path here and only use single quotes
$deps = (Join-Path $scriptDir 'setup-deps.sh') -replace '\\', '/'
$deps = [regex]::Replace($deps, '^([A-Za-z]):', { param($m) '/' + $m.Groups[1].Value.ToLower() })
Invoke-Msys2 "bash '$deps'"

Write-Host ""
Write-Host "Build environment ready. To run RemoteBox from the source tree:"
if ($Msys2Root -ne 'C:\msys64') { Write-Host "    set MSYS2_ROOT=$Msys2Root" }
Write-Host "    misc\windows\remotebox-dev.cmd"

<#
.SYNOPSIS
    Installs HanLock for the current user (no administrator rights, no registry changes).

.DESCRIPTION
    Copies HanLock.exe and the bundled license/docs next to it into the install
    directory, creates a per-user Startup shortcut (HanLock.lnk) pointing straight
    at the installed EXE, and starts it. On reinstall only a running HanLock
    process whose executable path is exactly the installed EXE is stopped.

.PARAMETER SourcePath
    HanLock.exe to install. Default: HanLock.exe next to this script. The bundled
    files (README.md, LICENSE, THIRD-PARTY-NOTICES.md, third-party\, install.ps1,
    uninstall.ps1) are taken from the same folder as the EXE.

.PARAMETER InstallDirectory
    Destination folder. Default: %LOCALAPPDATA%\HanLock. Paths may contain spaces.

.PARAMETER StartupDirectory
    Folder that receives HanLock.lnk. Default: current user's Startup folder.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -InstallDirectory "D:\Tools\Han Lock" -StartupDirectory "D:\Temp\Startup"
#>
[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot 'HanLock.exe'),
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'HanLock'),
    [string]$StartupDirectory = [Environment]::GetFolderPath('Startup')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$BundledFiles = @(
    'README.md',
    'LICENSE',
    'THIRD-PARTY-NOTICES.md',
    'third-party\AutoHotkey-LICENSE.txt',
    'install.ps1',
    'uninstall.ps1'
)

function Resolve-FullPath([string]$Path) {
    return [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $Path))
}

function Stop-InstalledHanLock([string]$ExePath) {
    $name = [IO.Path]::GetFileNameWithoutExtension($ExePath)
    $matching = @(Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and [string]::Equals($_.Path, $ExePath, [StringComparison]::OrdinalIgnoreCase)
    })
    foreach ($process in $matching) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    foreach ($process in $matching) {
        [void]$process.WaitForExit(10000)
    }
}

$source = Resolve-FullPath $SourcePath
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "HanLock.exe not found: $source" }
$sourceDirectory = Split-Path -Parent $source
foreach ($relative in $BundledFiles) {
    $bundled = Join-Path $sourceDirectory $relative
    if (-not (Test-Path -LiteralPath $bundled -PathType Leaf)) {
        throw "Required bundled file missing: $relative. Extract the complete release ZIP before installing."
    }
}

$installDir  = Resolve-FullPath $InstallDirectory
$startupDir  = Resolve-FullPath $StartupDirectory
$installedExe = Join-Path $installDir 'HanLock.exe'
$shortcutPath = Join-Path $startupDir 'HanLock.lnk'

Stop-InstalledHanLock $installedExe

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
New-Item -ItemType Directory -Force -Path $startupDir | Out-Null

if (-not [string]::Equals($source, $installedExe, [StringComparison]::OrdinalIgnoreCase)) {
    Copy-Item -LiteralPath $source -Destination $installedExe -Force
}
foreach ($relative in $BundledFiles) {
    $from = Join-Path $sourceDirectory $relative
    $to   = Join-Path $installDir $relative
    if ([string]::Equals($from, $to, [StringComparison]::OrdinalIgnoreCase)) { continue }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to) | Out-Null
    Copy-Item -LiteralPath $from -Destination $to -Force
}

$shell = New-Object -ComObject WScript.Shell
try {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $installedExe
    $shortcut.WorkingDirectory = $installDir
    $shortcut.Description = 'HanLock by lio'
    $shortcut.Save()
} finally {
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
}

Start-Process -FilePath $installedExe -WorkingDirectory $installDir

Write-Host "Installed: $installedExe"
Write-Host "Startup shortcut: $shortcutPath"

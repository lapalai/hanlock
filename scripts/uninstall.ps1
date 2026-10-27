<#
.SYNOPSIS
    Removes the per-user HanLock installation created by install.ps1.

.DESCRIPTION
    Stops only the HanLock process running from the exact installed EXE, removes
    the HanLock.lnk startup shortcut (only if it points at that EXE), deletes the
    files install.ps1 placed in the install directory, and removes the install
    directory (and its third-party subfolder) only if it is then empty. Unrelated
    files are never touched. No administrator rights or registry changes.

.PARAMETER InstallDirectory
    Folder used at install time. Default: %LOCALAPPDATA%\HanLock. Paths may contain spaces.

.PARAMETER StartupDirectory
    Folder holding HanLock.lnk. Default: current user's Startup folder.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File uninstall.ps1 -InstallDirectory "D:\Tools\Han Lock" -StartupDirectory "D:\Temp\Startup"
#>
[CmdletBinding()]
param(
    [string]$InstallDirectory = (Join-Path $env:LOCALAPPDATA 'HanLock'),
    [string]$StartupDirectory = [Environment]::GetFolderPath('Startup')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$InstalledFiles = @(
    'HanLock.exe',
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

function Remove-DirectoryIfEmpty([string]$Path) {
    if ((Test-Path -LiteralPath $Path -PathType Container) -and
        -not (Get-ChildItem -LiteralPath $Path -Force | Select-Object -First 1)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

$installDir   = Resolve-FullPath $InstallDirectory
$startupDir   = Resolve-FullPath $StartupDirectory
$installedExe = Join-Path $installDir 'HanLock.exe'
$shortcutPath = Join-Path $startupDir 'HanLock.lnk'

# Stop only the process running from the exact installed EXE.
$matching = @(Get-Process -Name 'HanLock' -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -and [string]::Equals($_.Path, $installedExe, [StringComparison]::OrdinalIgnoreCase)
})
foreach ($process in $matching) {
    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
}
foreach ($process in $matching) {
    [void]$process.WaitForExit(10000)
}

# Remove the startup shortcut only if it is ours.
if (Test-Path -LiteralPath $shortcutPath -PathType Leaf) {
    $shell = New-Object -ComObject WScript.Shell
    try {
        $target = $shell.CreateShortcut($shortcutPath).TargetPath
    } finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
    if ([string]::Equals($target, $installedExe, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $shortcutPath -Force
        Write-Host "Removed startup shortcut: $shortcutPath"
    } else {
        Write-Warning "Startup shortcut points elsewhere, left in place: $shortcutPath"
    }
}

# Remove only the files install.ps1 placed, then empty directories.
foreach ($relative in $InstalledFiles) {
    $path = Join-Path $installDir $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
}
Remove-DirectoryIfEmpty (Join-Path $installDir 'third-party')
Remove-DirectoryIfEmpty $installDir
if (Test-Path -LiteralPath $installDir -PathType Container) {
    Write-Warning "Install directory contains other files, left in place: $installDir"
}

Write-Host 'HanLock uninstalled.'

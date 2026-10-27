<#
.SYNOPSIS
    Builds the portable HanLock Windows x64 package into dist/.

.DESCRIPTION
    Downloads pinned official AutoHotkey v2 and Ahk2Exe packages into .tools/
    (SHA256 verified on download and on every cached reuse), compiles
    src/HanLock.ahk with AutoHotkey64.exe as the base, and creates:

      dist/HanLock.exe
      dist/README.md, LICENSE, THIRD-PARTY-NOTICES.md
      dist/third-party/AutoHotkey-LICENSE.txt
      dist/install.ps1, dist/uninstall.ps1
      dist/HanLock-<version>-windows-x64.zip      (binary package)
      dist/AutoHotkey-<runtime>-source.zip        (corresponding runtime source)

    No system-wide installation is required. Works on Windows PowerShell 5.1.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Version        = '1.0.0'
$RuntimeVersion = '2.0.31'

$Packages = @(
    @{
        Name   = 'AutoHotkey'
        File   = "AutoHotkey_$RuntimeVersion.zip"
        Url    = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$RuntimeVersion/AutoHotkey_$RuntimeVersion.zip"
        Sha256 = 'ca1a595aca4528755d8d4cd7fed23d497a37bd9a0b6892072612d68dee1bd00a'
    },
    @{
        Name   = 'Ahk2Exe'
        File   = 'Ahk2Exe1.1.37.02a2.zip'
        Url    = 'https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe1.1.37.02a2/Ahk2Exe1.1.37.02a2.zip'
        Sha256 = 'c29b8c3a5124850d79fc9e66e2ca79677c377d7f31631ad3022ba159c5d9e3be'
    }
)
$SourceArchiveUrl = "https://api.github.com/repos/AutoHotkey/AutoHotkey/zipball/v$RuntimeVersion"

$Root     = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Tools    = Join-Path $Root '.tools'
$Dist     = Join-Path $Root 'dist'
$Script   = Join-Path $Root 'src\HanLock.ahk'
$PackageName = "HanLock-$Version-windows-x64"
$ZipPath     = Join-Path $Dist "$PackageName.zip"
$SourceZip   = Join-Path $Dist "AutoHotkey-$RuntimeVersion-source.zip"

function Get-Sha256([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($stream)) -replace '-', '').ToLowerInvariant()
    } finally {
        $stream.Dispose()
        $sha.Dispose()
    }
}

function Download-File([string]$Url, [string]$Destination) {
    $partial = "$Destination.partial"
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
    Invoke-WebRequest -Uri $Url -OutFile $partial -UseBasicParsing -UserAgent 'HanLock-build' -MaximumRedirection 10
    Move-Item -LiteralPath $partial -Destination $Destination -Force
}

function Expand-Zip([string]$Archive, [string]$Destination) {
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
    [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
}

function Assert-ZipReadable([string]$Path) {
    $zip = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        if ($zip.Entries.Count -eq 0) { throw "Archive is empty: $Path" }
    } finally {
        $zip.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $Script -PathType Leaf)) { throw "Source script not found: $Script" }

# Required documentation / packaging inputs (supplied by the repository).
$StaticFiles = @(
    'README.md',
    'LICENSE',
    'THIRD-PARTY-NOTICES.md',
    'third-party\AutoHotkey-LICENSE.txt',
    'scripts\install.ps1',
    'scripts\uninstall.ps1'
)
foreach ($relative in $StaticFiles) {
    $path = Join-Path $Root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required package file missing: $relative" }
}

New-Item -ItemType Directory -Force -Path $Tools | Out-Null

# 1. Pinned toolchain: download if missing/corrupt, always verify, extract fresh.
foreach ($pkg in $Packages) {
    $archive = Join-Path $Tools $pkg.File
    if (Test-Path -LiteralPath $archive -PathType Leaf) {
        if ((Get-Sha256 $archive) -ne $pkg.Sha256) {
            Write-Host "Cached $($pkg.File) hash mismatch; downloading again."
            Remove-Item -LiteralPath $archive -Force
        }
    }
    if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) {
        Write-Host "Downloading $($pkg.Url)"
        Download-File $pkg.Url $archive
    }
    $actual = Get-Sha256 $archive
    if ($actual -ne $pkg.Sha256) {
        Remove-Item -LiteralPath $archive -Force
        throw "SHA256 mismatch for $($pkg.File): expected $($pkg.Sha256), got $actual"
    }
    Write-Host "Verified $($pkg.File) ($actual)"
    Expand-Zip $archive (Join-Path $Tools $pkg.Name)
}

$BaseExe = Join-Path $Tools 'AutoHotkey\AutoHotkey64.exe'
$Ahk2Exe = Join-Path $Tools 'Ahk2Exe\Ahk2Exe.exe'
foreach ($required in @($BaseExe, $Ahk2Exe)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Toolchain file missing after extraction: $required" }
}

# 2. Corresponding runtime source (GitHub zipball for the pinned tag).
$sourceCache = Join-Path $Tools "AutoHotkey-$RuntimeVersion-source.zip"
$sourceOk = $false
if (Test-Path -LiteralPath $sourceCache -PathType Leaf) {
    try { Assert-ZipReadable $sourceCache; $sourceOk = $true } catch { Remove-Item -LiteralPath $sourceCache -Force }
}
if (-not $sourceOk) {
    Write-Host "Downloading $SourceArchiveUrl"
    Download-File $SourceArchiveUrl $sourceCache
    Assert-ZipReadable $sourceCache
}

# 3. Clean only the artifacts this script owns, then compile.
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
foreach ($owned in @('HanLock.exe', 'README.md', 'LICENSE', 'THIRD-PARTY-NOTICES.md', 'install.ps1', 'uninstall.ps1')) {
    $path = Join-Path $Dist $owned
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}
$distThirdParty = Join-Path $Dist 'third-party'
if (Test-Path -LiteralPath $distThirdParty) { Remove-Item -LiteralPath $distThirdParty -Recurse -Force }
foreach ($old in @($ZipPath, $SourceZip)) {
    if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Force }
}
& (Join-Path $PSScriptRoot 'icon.ps1')

$ExePath = Join-Path $Dist 'HanLock.exe'
$logOut = Join-Path $Tools 'ahk2exe.out.log'
$logErr = Join-Path $Tools 'ahk2exe.err.log'
$compilerArgs = @(
    '/in',   "`"$Script`"",
    '/out',  "`"$ExePath`"",
    '/base', "`"$BaseExe`"",
    '/cp',   '65001',
    '/icon', "`"$(Join-Path $Root 'assets\hanlock.ico')`"",
    '/compress', '0',
    '/silent', 'verbose'
)
Write-Host 'Compiling HanLock.exe'
$proc = Start-Process -FilePath $Ahk2Exe -ArgumentList $compilerArgs -Wait -PassThru -NoNewWindow `
    -RedirectStandardOutput $logOut -RedirectStandardError $logErr
foreach ($log in @($logOut, $logErr)) {
    if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | ForEach-Object { Write-Host $_ } }
}
if ($proc.ExitCode -ne 0) { throw "Ahk2Exe failed with exit code $($proc.ExitCode)" }
if (-not (Test-Path -LiteralPath $ExePath -PathType Leaf)) { throw "Ahk2Exe did not produce $ExePath" }

# 4. Stage package files next to the EXE.
New-Item -ItemType Directory -Force -Path $distThirdParty | Out-Null
foreach ($relative in $StaticFiles) {
    $target = Join-Path $Dist (Split-Path -Leaf $relative)
    if ($relative -like 'third-party\*') { $target = Join-Path $distThirdParty (Split-Path -Leaf $relative) }
    Copy-Item -LiteralPath (Join-Path $Root $relative) -Destination $target -Force
}

# 5. Binary ZIP: only the package files, forward-slash entry names, one top folder.
$PackageFiles = @(
    'HanLock.exe', 'README.md', 'LICENSE', 'THIRD-PARTY-NOTICES.md',
    'third-party/AutoHotkey-LICENSE.txt', 'install.ps1', 'uninstall.ps1'
)
$zipStream = [IO.File]::Open($ZipPath, [IO.FileMode]::CreateNew)
try {
    $zip = New-Object IO.Compression.ZipArchive($zipStream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        foreach ($relative in $PackageFiles) {
            $file = Join-Path $Dist ($relative -replace '/', '\')
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $file, "$PackageName/$relative", [IO.Compression.CompressionLevel]::Optimal)
        }
    } finally {
        $zip.Dispose()
    }
} finally {
    $zipStream.Dispose()
}

Copy-Item -LiteralPath $sourceCache -Destination $SourceZip -Force

foreach ($artifact in @($ExePath, $ZipPath, $SourceZip)) {
    if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) { throw "Missing build artifact: $artifact" }
    Write-Host ("{0}  {1}  {2}" -f (Get-Sha256 $artifact), (Split-Path -Leaf $artifact), (Get-Item -LiteralPath $artifact).Length)
}
Write-Host 'Build complete.'

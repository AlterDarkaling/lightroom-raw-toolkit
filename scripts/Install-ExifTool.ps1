<#
.SYNOPSIS
  Automatically download and set up the official 64-bit Windows ExifTool into tools\.
  Also supports installing from a local -ZipPath for offline or test usage.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]$TargetDir,
    [string]$ZipPath,
    [switch]$SkipVerify,
    [ValidateSet('auto', 'zh', 'en')]
    [string]$Lang = 'auto'
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$scriptDir   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = [IO.Path]::GetDirectoryName($scriptDir.TrimEnd('\', '/'))
if (-not $projectRoot -or -not (Test-Path -LiteralPath (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1') -PathType Leaf)) {
    $projectRoot = $scriptDir
}

. (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1')
Set-UiLang $Lang

if (-not $TargetDir) {
    $TargetDir = Join-Path $projectRoot 'tools'
}

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host ""
Write-Host (T 'EtInstBanner') -ForegroundColor Cyan

$tmpDir = Join-Path $env:TEMP ("lrt_et_inst_{0}" -f $PID)
$prevProg = $ProgressPreference
try {
    if (Test-Path -LiteralPath $tmpDir) {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    $useZip = $ZipPath
    if (-not $useZip) {
        Write-Host (T 'EtInstFetchingVer') -ForegroundColor DarkGray
        $downloadUrl = $null
        try {
            $homeHtml = (Invoke-WebRequest -Uri 'https://exiftool.org/' -UseBasicParsing -TimeoutSec 20).Content
            if ($homeHtml -match 'href="(https?://[^"]*exiftool[^"]*64\.zip[^"]*)"') {
                $downloadUrl = $matches[1]
            }
        } catch {}

        if (-not $downloadUrl) {
            $verStr = (Invoke-WebRequest -Uri 'https://exiftool.org/ver.txt' -UseBasicParsing -TimeoutSec 20).Content.Trim()
            if (-not $verStr) {
                throw "Failed to read ExifTool version from exiftool.org"
            }
            $downloadUrl = "https://sourceforge.net/projects/exiftool/files/exiftool-$verStr`_64.zip/download"
        }

        Write-Host (T 'EtInstDownloading' @($downloadUrl)) -ForegroundColor Cyan
        $dlZip = Join-Path $tmpDir 'exiftool_64.zip'
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -Headers @{ 'User-Agent' = 'curl/8.0' } -UseBasicParsing -TimeoutSec 120 -OutFile $dlZip
        if (-not (Test-Path -LiteralPath $dlZip -PathType Leaf)) {
            throw (T 'EtInstBadZip')
        }
        $dlItem = Get-Item -LiteralPath $dlZip
        $headBytes = [IO.File]::ReadAllBytes($dlZip)
        $isZipSig = ($headBytes.Length -ge 2 -and $headBytes[0] -eq 0x50 -and $headBytes[1] -eq 0x4B)
        if ($dlItem.Length -lt 102400 -or -not $isZipSig) {
            throw (T 'EtInstBadZip')
        }
        $useZip = $dlZip
    } else {
        if (-not (Test-Path -LiteralPath $useZip -PathType Leaf)) {
            throw (T 'EtInstBadZip')
        }
        $headBytes = [IO.File]::ReadAllBytes($useZip)
        $isZipSig = ($headBytes.Length -ge 2 -and $headBytes[0] -eq 0x50 -and $headBytes[1] -eq 0x4B)
        if (-not $isZipSig) {
            throw (T 'EtInstBadZip')
        }
    }

    Write-Host (T 'EtInstExtracting' @($TargetDir)) -ForegroundColor DarkGray
    $extractDir = Join-Path $tmpDir 'extract'
    [System.IO.Compression.ZipFile]::ExtractToDirectory($useZip, $extractDir)

    $exeFile = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Filter 'exiftool(-k).exe' | Select-Object -First 1
    if (-not $exeFile) {
        $exeFile = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Filter 'exiftool.exe' | Select-Object -First 1
    }
    if (-not $exeFile) {
        throw (T 'EtInstNoExeInZip')
    }

    if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    $targetExe = Join-Path $TargetDir 'exiftool.exe'
    Copy-Item -LiteralPath $exeFile.FullName -Destination $targetExe -Force

    $srcFilesDir = Join-Path $exeFile.DirectoryName 'exiftool_files'
    if (Test-Path -LiteralPath $srcFilesDir -PathType Container) {
        $dstFilesDir = Join-Path $TargetDir 'exiftool_files'
        if (Test-Path -LiteralPath $dstFilesDir -PathType Container) {
            Remove-Item -LiteralPath $dstFilesDir -Recurse -Force
        }
        Copy-Item -LiteralPath $srcFilesDir -Destination $dstFilesDir -Recurse -Force
    }

    $verOut = 'ok'
    if (-not $SkipVerify.IsPresent) {
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $verOut = ((& $targetExe -ver 2>$null) | Out-String).Trim()
            if ($LASTEXITCODE -ne 0 -or -not $verOut) {
                throw "exiftool.exe -ver failed (exit=$LASTEXITCODE)"
            }
        } finally {
            $ErrorActionPreference = $prevEap
        }
    }

    Write-Host (T 'EtInstOk' @($verOut, $targetExe)) -ForegroundColor Green
    $instOk = $true
} catch {
    Write-Host (T 'EtInstFail' @($_.Exception.Message)) -ForegroundColor Red
    Write-Host (T 'EtInstManualHint') -ForegroundColor Yellow
    $instOk = $false
} finally {
    $ProgressPreference = $prevProg
    if (Test-Path -LiteralPath $tmpDir) {
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
if ($instOk) { exit 0 } else { exit 1 }

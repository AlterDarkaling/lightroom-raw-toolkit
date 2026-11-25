<#
.SYNOPSIS
  Losslessly roll back JPG files modified by Restore-RatingToJpg.ps1 using the
  centralized backups under <ProjectRoot>\backups\jpg_restore_*.
  Restores exact original bytes and LastWriteTimeUtc.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]$BackupDir,
    [string]$JpgRoot,
    [switch]$DryRun,
    [switch]$NoConfirm,
    [switch]$RemoveBackupAfter,
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

$backupRoot = Join-Path $projectRoot 'backups'

if (-not $BackupDir) {
    if (-not (Test-Path -LiteralPath $backupRoot -PathType Container)) {
        Write-Host (T 'RbNoBackups' @($backupRoot)) -ForegroundColor Yellow
        exit 0
    }
    $dirs = @(Get-ChildItem -LiteralPath $backupRoot -Directory -Filter 'jpg_restore_*' | Sort-Object Name -Descending)
    if ($dirs.Count -eq 0) {
        Write-Host (T 'RbNoBackups' @($backupRoot)) -ForegroundColor Yellow
        exit 0
    }

    Write-Host ""
    Write-Host (T 'RbBanner') -ForegroundColor Cyan
    Write-Host (T 'RbListHeader') -ForegroundColor Yellow
    $idx = 0
    foreach ($d in $dirs) {
        $idx++
        $mfPath = Join-Path $d.FullName 'manifest.json'
        $mfRoot = '?'
        if (Test-Path -LiteralPath $mfPath -PathType Leaf) {
            try {
                $mfObj = ([IO.File]::ReadAllText($mfPath, [System.Text.Encoding]::UTF8)) | ConvertFrom-Json
                if ($mfObj.JpgRoot) { $mfRoot = $mfObj.JpgRoot }
            } catch {}
        }
        $items = @(Get-ChildItem -LiteralPath $d.FullName -Recurse -File | Where-Object { $_.Name -ine 'manifest.json' })
        $sumBytes = 0L
        foreach ($it in $items) { $sumBytes += $it.Length }
        Write-Host (T 'RbListItem' @($idx, $d.Name, $items.Count, (Format-Size $sumBytes), $mfRoot))
    }

    $selRaw = Read-Host (T 'RbSelectPrompt')
    if ($null -eq $selRaw) { Write-Host (T 'RbCancelled') -ForegroundColor Yellow; exit 0 }
    $sel = $selRaw.Trim()
    if (-not $sel -or $sel -eq '0') {
        Write-Host (T 'RbCancelled') -ForegroundColor Yellow
        exit 0
    }
    $selNum = 0
    if (-not [int]::TryParse($sel, [ref]$selNum) -or $selNum -lt 1 -or $selNum -gt $dirs.Count) {
        Write-Host (T 'RbInvalidSel' @($sel)) -ForegroundColor Red
        exit 1
    }
    $BackupDir = $dirs[$selNum - 1].FullName
}

if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) {
    Write-Host (T 'RbErrNoDir' @($BackupDir)) -ForegroundColor Red
    exit 1
}
$BackupDir = (Resolve-Path -LiteralPath $BackupDir).Path.TrimEnd('\', '/')

$manifestPath = Join-Path $BackupDir 'manifest.json'
$targetRoot = $JpgRoot
if (-not $targetRoot -and (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    try {
        $mf = ([IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8)) | ConvertFrom-Json
        if ($mf.JpgRoot) { $targetRoot = $mf.JpgRoot }
    } catch {}
}
if (-not $targetRoot -or -not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
    Write-Host (T 'RbErrNoTargetRoot') -ForegroundColor Red
    exit 1
}
$targetRoot = (Resolve-Path -LiteralPath $targetRoot).Path.TrimEnd('\', '/')

$backupFiles = @(Get-ChildItem -LiteralPath $BackupDir -Recurse -File | Where-Object {
    $_.Name -ine 'manifest.json' -and $_.Length -gt 0
})
if ($backupFiles.Count -eq 0) {
    Write-Host (T 'RbErrEmpty' @($BackupDir)) -ForegroundColor Yellow
    exit 0
}

$totalBackupBytes = 0L
foreach ($bf in $backupFiles) { $totalBackupBytes += $bf.Length }
$formatRbLine = {
    param($SrcFile)
    $rel = if ($SrcFile.FullName.StartsWith($BackupDir + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $SrcFile.FullName.Substring($BackupDir.Length + 1)
    } else {
        $SrcFile.Name
    }
    "    {0}  ({1})" -f $rel, (Format-Size $SrcFile.Length)
}

Write-Host ""
Write-Host (T 'RbBanner') -ForegroundColor Cyan
Write-Host (T 'RbPreviewInfo' @($BackupDir))
Write-Host (T 'RbTargetInfo'  @($targetRoot))
Write-Host (T 'RbFileCount'   @($backupFiles.Count, (Format-Size $totalBackupBytes))) -ForegroundColor Yellow
$rbSampleN = [Math]::Min(10, $backupFiles.Count)
Write-Host (T 'PreviewSampleHeader' @($rbSampleN, $backupFiles.Count)) -ForegroundColor Cyan
for ($idx = 0; $idx -lt $rbSampleN; $idx++) {
    Write-Host (& $formatRbLine $backupFiles[$idx]) -ForegroundColor Gray
}
if ($backupFiles.Count -gt 10) {
    Write-Host (T 'PreviewSampleMore' @($backupFiles.Count - 10)) -ForegroundColor DarkGray
}
Write-Host "==========================================" -ForegroundColor Cyan

if ($DryRun.IsPresent) {
    Write-Host ""
    Write-Host (T 'RbDryDone') -ForegroundColor Yellow
    exit 0
}

if (-not $NoConfirm.IsPresent) {
    Write-Host ""
    Write-Host (T 'RbConfirmNote') -ForegroundColor Yellow
    while ($true) {
        $ansRaw = Read-Host (T 'RbConfirmPrompt')
        if ($null -eq $ansRaw) {
            Write-Host (T 'RbCancelled') -ForegroundColor Yellow
            exit 0
        }
        $ans = $ansRaw.Trim()
        if ($ans -in @('V', 'v')) {
            Write-Host ""
            Write-Host (T 'PreviewAllHeader' @($backupFiles.Count)) -ForegroundColor Cyan
            for ($idx = 0; $idx -lt $backupFiles.Count; $idx++) {
                $lineTxt = (& $formatRbLine $backupFiles[$idx]).TrimStart()
                Write-Host ("  [{0}/{1}] {2}" -f ($idx + 1), $backupFiles.Count, $lineTxt) -ForegroundColor Gray
            }
            Write-Host (T 'PreviewAllEnd') -ForegroundColor Cyan
            Write-Host ""
            continue
        }
        if ($ans -in @('Y', 'y')) { break }
        Write-Host (T 'RbCancelled') -ForegroundColor Yellow
        exit 0
    }
}

$restored = 0
$failed   = 0
foreach ($src in $backupFiles) {
    $rel = if ($src.FullName.StartsWith($BackupDir + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $src.FullName.Substring($BackupDir.Length + 1)
    } else {
        $src.Name
    }
    $dst = Join-Path $targetRoot $rel
    $dstDir = [IO.Path]::GetDirectoryName($dst)
    try {
        if (-not (Test-Path -LiteralPath $dstDir -PathType Container)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        $srcLen = $src.Length
        $srcUtc = $src.LastWriteTimeUtc
        [IO.File]::Copy($src.FullName, $dst, $true)
        [IO.File]::SetLastWriteTimeUtc($dst, $srcUtc)
        if ((Get-Item -LiteralPath $dst).Length -ne $srcLen) {
            throw "Length mismatch after copy"
        }
        $restored++
    } catch {
        Write-Host (T 'RbFailItem' @($dst, $_.Exception.Message)) -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host (T 'RbDoneSummary' @($restored, $failed)) -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Yellow' })
$shouldRemove = $false
if ($failed -eq 0) {
    if ($RemoveBackupAfter.IsPresent) {
        $shouldRemove = $true
    } elseif (-not $NoConfirm.IsPresent) {
        $rmAns = Read-Host (T 'RbPromptRemoveBackup' @((Format-Size $totalBackupBytes)))
        if ($null -ne $rmAns -and ($rmAns.Trim() -in @('Y', 'y'))) {
            $shouldRemove = $true
        }
    }
}
if ($shouldRemove) {
    try {
        Remove-Item -LiteralPath $BackupDir -Recurse -Force
        Write-Host (T 'RbBackupRemoved' @($BackupDir)) -ForegroundColor DarkGray
    } catch {
        Write-Host (T 'RbBackupKept' @($BackupDir)) -ForegroundColor DarkGray
    }
} else {
    Write-Host (T 'RbBackupKept' @($BackupDir)) -ForegroundColor DarkGray
}
Write-Host (T 'RbCloudTip') -ForegroundColor Magenta
if ($failed -gt 0) { exit 1 }

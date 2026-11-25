<#
.SYNOPSIS
  Unified interactive launcher menu for lightroom-raw-toolkit.
  Supports switching target photo folder, toggling zh/en language live,
  and launching Clean-RawToRecycleBin.ps1 or Restore-RatingToJpg.ps1.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]$RootPath,
    [string]$ExifToolPath,
    [string]$CatalogPath,
    [ValidateSet('auto', 'zh', 'en')]
    [string]$Lang = 'auto',
    [string[]]$AutoChoices,
    [switch]$NoConfig
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$scriptDir   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = [IO.Path]::GetDirectoryName($scriptDir.TrimEnd('\', '/'))
if (-not $projectRoot -or -not (Test-Path -LiteralPath (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1') -PathType Leaf)) {
    $projectRoot = $scriptDir
}

. (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1')

$localCfg = if (-not $NoConfig.IsPresent) { Get-ToolkitLocalConfig -ProjectRoot $projectRoot } else { $null }
if ($Lang -ieq 'auto' -and $localCfg -and $localCfg.Lang -in @('zh', 'en')) {
    $currentLang = $localCfg.Lang
} else {
    $currentLang = Resolve-UiLang $Lang
}
Set-UiLang $currentLang

if ($RootPath) {
    if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
        Write-Host (T 'ErrNoRoot' @($RootPath)) -ForegroundColor Red
        exit 1
    }
    $currentRoot = (Resolve-Path -LiteralPath $RootPath).Path
} elseif ($localCfg -and $localCfg.LastRoot -and (Test-Path -LiteralPath $localCfg.LastRoot -PathType Container)) {
    $currentRoot = (Resolve-Path -LiteralPath $localCfg.LastRoot).Path
} else {
    $currentRoot = Resolve-DefaultPhotoRoot -ScriptDir $projectRoot -AllowJpg $true
    if (Test-Path -LiteralPath $currentRoot -PathType Container) {
        $currentRoot = (Resolve-Path -LiteralPath $currentRoot).Path
    }
}

$cleanScript    = Join-Path $projectRoot 'scripts\Clean-RawToRecycleBin.ps1'
$restoreScript  = Join-Path $projectRoot 'scripts\Restore-RatingToJpg.ps1'
$rollbackScript = Join-Path $projectRoot 'scripts\Rollback-JpgBackup.ps1'
$autoIdx        = 0

while ($true) {
    Set-UiLang $currentLang
    $langLabel = if ($currentLang -eq 'zh') { '简体中文 (zh)' } else { 'English (en)' }

    $checkEt  = Resolve-ExifToolPath -ExplicitPath $ExifToolPath -ProjectRoot $projectRoot -ScriptDir $scriptDir
    $etReady  = ($checkEt -and (Test-Path -LiteralPath $checkEt -PathType Leaf))
    $checkCat = Resolve-CatalogPath -ExplicitPath $CatalogPath -PhotoRoot $currentRoot
    $catReady = ($checkCat -and (Test-Path -LiteralPath $checkCat -PathType Leaf))
    $catLock  = ($catReady -and (Test-Path -LiteralPath ($checkCat + '.lock')))
    $dbReady  = ((Resolve-SqliteCliPath -ProjectRoot $projectRoot -ScriptDir $scriptDir) -or (Resolve-PythonCliPath))

    Write-Host ""
    Write-Host (T 'MenuTitle') -ForegroundColor Cyan
    Write-Host (T 'MenuCurrentRoot' @($currentRoot))
    Write-Host (T 'MenuCurrentLang' @($langLabel))
    if ($etReady) {
        Write-Host (T 'MenuEnvExifOk' @($checkEt)) -ForegroundColor Green
    } else {
        Write-Host (T 'MenuEnvExifMissing') -ForegroundColor Red
    }
    if ($catLock) {
        Write-Host (T 'MenuEnvCatLocked' @($checkCat)) -ForegroundColor Yellow
    } elseif ($catReady) {
        Write-Host (T 'MenuEnvCatOk' @($checkCat)) -ForegroundColor Green
    } else {
        Write-Host (T 'MenuEnvCatMissing') -ForegroundColor DarkGray
    }
    if (-not $dbReady) {
        Write-Host (T 'MenuEnvNoSqlite') -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host (T 'MenuOptClean')      -ForegroundColor White
    Write-Host (T 'MenuOptRestore')    -ForegroundColor White
    Write-Host (T 'MenuOptRollback')   -ForegroundColor White
    Write-Host (T 'MenuOptSwitchRoot') -ForegroundColor Yellow
    Write-Host (T 'MenuOptSwitchLang') -ForegroundColor Yellow
    Write-Host (T 'MenuOptExit')       -ForegroundColor DarkGray
    Write-Host "==============================================" -ForegroundColor Cyan

    if ($AutoChoices -and $AutoChoices.Count -gt 0) {
        if ($autoIdx -ge $AutoChoices.Count) { break }
        $choice = $AutoChoices[$autoIdx]
        $autoIdx++
    } else {
        $choice = Read-Host (T 'MenuPrompt')
        if ($null -eq $choice) { break }
    }
    $choice = $choice.Trim()

    if ($choice -eq '0') {
        Write-Host (T 'MenuBye') -ForegroundColor DarkGray
        break
    } elseif ($choice -ieq 'L') {
        $currentLang = if ($currentLang -eq 'zh') { 'en' } else { 'zh' }
        if (-not $NoConfig.IsPresent) {
            Save-ToolkitLocalConfig -ProjectRoot $projectRoot -LastRoot $currentRoot -Lang $currentLang
        }
        continue
    } elseif ($choice -eq '4') {
        $newRoot = Read-Host (T 'MenuSwitchRootPrompt')
        if ($null -eq $newRoot) { break }
        $newRoot = $newRoot.Trim().Trim('"')
        if ($newRoot) {
            if (Test-Path -LiteralPath $newRoot -PathType Container) {
                $currentRoot = (Resolve-Path -LiteralPath $newRoot).Path
                Write-Host (T 'BannerSwitchedRoot' @($currentRoot)) -ForegroundColor Green
                if (-not $NoConfig.IsPresent) {
                    Save-ToolkitLocalConfig -ProjectRoot $projectRoot -LastRoot $currentRoot -Lang $currentLang
                }
            } else {
                Write-Host (T 'ErrNoRoot' @($newRoot)) -ForegroundColor Red
            }
        }
        continue
    } elseif ($choice -eq '1') {
        $params = @{
            RootPath = $currentRoot
            Lang     = $currentLang
        }
        if ($ExifToolPath) { $params['ExifToolPath'] = $ExifToolPath }
        if ($CatalogPath)  { $params['CatalogPath']  = $CatalogPath }
        & $cleanScript @params
        $null = Read-Host (T 'MenuPressEnter')
    } elseif ($choice -eq '2') {
        $params = @{
            JpgRoot = $currentRoot
            Lang    = $currentLang
        }
        if ($ExifToolPath) { $params['ExifToolPath'] = $ExifToolPath }
        if ($CatalogPath)  { $params['CatalogPath']  = $CatalogPath }
        & $restoreScript @params
        $null = Read-Host (T 'MenuPressEnter')
    } elseif ($choice -eq '3') {
        & $rollbackScript -Lang $currentLang
        $null = Read-Host (T 'MenuPressEnter')
    } else {
        Write-Host (T 'MenuInvalidOpt' @($choice)) -ForegroundColor Yellow
    }
}

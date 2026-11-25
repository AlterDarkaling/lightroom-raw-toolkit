<#
.SYNOPSIS
  Move unrated RAW files older than a cutoff date to the Windows Recycle Bin.
  Supports multi-brand RAW formats, XMP sidecars, companion JPG/HIF ratings,
  RAW-only protection, and read-only Lightroom catalog checks.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]  $BeforeDate,
    [int]     $KeepRecentDays,
    [string]  $RootPath,
    [string[]]$RawExtensions,
    [switch]  $UseFileDate,
    [string]  $ExifToolPath,
    [string]  $CatalogPath,
    [switch]  $NoCatalog,
    [string]  $PixCakeDbRoot,
    [switch]  $DeleteRawOnly,
    [switch]  $DryRun,
    [switch]  $NoConfirm,
    [switch]  $DeleteRated,
    [ValidateSet('auto', 'zh', 'en')]
    [string]  $Lang = 'auto'
)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$scriptDir   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = [IO.Path]::GetDirectoryName($scriptDir.TrimEnd('\', '/'))
if (-not $projectRoot -or -not (Test-Path -LiteralPath (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1') -PathType Leaf)) {
    $projectRoot = $scriptDir
}

. (Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1')
Set-UiLang $Lang

try { Add-Type -AssemblyName Microsoft.VisualBasic }
catch {
    Write-Host (T 'ErrNoVisualBasic') -ForegroundColor Red
    exit 1
}

$rawExtList = if ($RawExtensions) { Normalize-ExtensionList $RawExtensions } else { Get-DefaultRawExtensions }
if (-not $rawExtList -or $rawExtList.Count -eq 0) {
    Write-Host (T 'ErrNoRawExt') -ForegroundColor Red
    exit 1
}
$rawExtSet = @{}
foreach ($ext in $rawExtList) { $rawExtSet[$ext] = $true }

$explicitRoot = [bool]$RootPath
if (-not $RootPath) {
    $RootPath = Resolve-DefaultPhotoRoot -ScriptDir $scriptDir -AllowJpg $false
}
if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
    Write-Host (T 'ErrNoRoot' @($RootPath)) -ForegroundColor Red
    exit 1
}
$RootPath = (Resolve-Path -LiteralPath $RootPath).Path

$ExifToolPath = Resolve-ExifToolPath -ExplicitPath $ExifToolPath -ProjectRoot $projectRoot -ScriptDir $scriptDir
$exifOk = Test-Path -LiteralPath $ExifToolPath -PathType Leaf
if ($exifOk) { $ExifToolPath = (Resolve-Path -LiteralPath $ExifToolPath).Path }
if (-not $DeleteRated -and -not $exifOk) {
    Write-Host (T 'ErrNoExifTool' @($ExifToolPath)) -ForegroundColor Red
    Write-Host (T 'ErrNoExifToolHint1') -ForegroundColor Red
    Write-Host (T 'ErrNoExifToolHint2') -ForegroundColor Red
    exit 1
}

$explicitCatalog = [bool]$CatalogPath
$detectedDbLabels = New-Object System.Collections.Generic.List[string]
if (-not $NoCatalog) {
    if ($explicitCatalog) {
        if (-not (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
            Write-Host (T 'ErrNoCatalog' @($CatalogPath)) -ForegroundColor Red
            exit 1
        }
        $CatalogPath = (Resolve-Path -LiteralPath $CatalogPath).Path
        $detectedDbLabels.Add($CatalogPath)
    } else {
        $lrCat = Resolve-CatalogPath -ExplicitPath $null -PhotoRoot $RootPath
        if ($lrCat -and (Test-Path -LiteralPath $lrCat -PathType Leaf)) {
            $CatalogPath = (Resolve-Path -LiteralPath $lrCat).Path
            $detectedDbLabels.Add($CatalogPath)
        }
        foreach ($c1 in (Resolve-CaptureOneCatalogPaths -ExplicitPath $null -PhotoRoot $RootPath)) {
            $detectedDbLabels.Add($c1)
        }
        $pxCount = @(Resolve-PixCakeDbPaths -PixCakeDbRoot $PixCakeDbRoot).Count
        if ($pxCount -gt 0) {
            $detectedDbLabels.Add("PixCake ($pxCount project DBs)")
        }
    }
} else {
    $CatalogPath = $null
}

if ($BeforeDate -and $KeepRecentDays) {
    Write-Host (T 'ErrBothDateFlags') -ForegroundColor Red
    exit 1
}
if (-not $BeforeDate -and -not $KeepRecentDays) {
    Write-Host ""
    Write-Host (T 'BannerTitle') -ForegroundColor Cyan
    Write-Host (T 'BannerDefaultRoot' @($RootPath))
    if (-not $explicitRoot) {
        $customRoot = (Read-Host (T 'PromptCustomRoot')).Trim().Trim('"')
        if ($customRoot) {
            if (-not (Test-Path -LiteralPath $customRoot -PathType Container)) {
                Write-Host (T 'ErrNoRoot' @($customRoot)) -ForegroundColor Red
                exit 1
            }
            $RootPath = (Resolve-Path -LiteralPath $customRoot).Path
            if (-not $NoCatalog -and -not $explicitCatalog) {
                $CatalogPath = Resolve-CatalogPath -ExplicitPath $null -PhotoRoot $RootPath
                if ($CatalogPath) { $CatalogPath = (Resolve-Path -LiteralPath $CatalogPath).Path }
            }
            Write-Host (T 'BannerSwitchedRoot' @($RootPath)) -ForegroundColor Cyan
        }
    }
    Write-Host (T 'PromptMode') -ForegroundColor Yellow
    $mRaw = Read-Host (T 'PromptChoice')
    if ($null -eq $mRaw) { Write-Host (T 'Cancelled') -ForegroundColor Yellow; exit 0 }
    $m = $mRaw.Trim()
    if (-not $m -or $m -eq '0') {
        Write-Host (T 'Cancelled') -ForegroundColor Yellow
        exit 0
    }
    if ($m -eq '2') {
        $daysIn = Read-Host (T 'PromptDays')
        if ($null -eq $daysIn) { Write-Host (T 'Cancelled') -ForegroundColor Yellow; exit 0 }
        $daysRaw = $daysIn.Trim()
        if (-not $daysRaw -or $daysRaw -eq '0') {
            Write-Host (T 'Cancelled') -ForegroundColor Yellow
            exit 0
        }
        $daysNum = 0
        if (-not [int]::TryParse($daysRaw, [ref]$daysNum)) {
            Write-Host (T 'ErrInvalidDays' @($daysRaw)) -ForegroundColor Red
            exit 1
        }
        $KeepRecentDays = $daysNum
    } elseif ($m -eq '1') {
        $bdIn = Read-Host (T 'PromptBeforeDate')
        if ($null -eq $bdIn) { Write-Host (T 'Cancelled') -ForegroundColor Yellow; exit 0 }
        $BeforeDate = $bdIn.Trim()
        if (-not $BeforeDate -or $BeforeDate -eq '0') {
            Write-Host (T 'Cancelled') -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host (T 'ErrInvalidChoice' @($m)) -ForegroundColor Red
        exit 1
    }
}

$inv = [Globalization.CultureInfo]::InvariantCulture
if ($BeforeDate) {
    try {
        $cutoff = [datetime]::ParseExact($BeforeDate.Trim(), 'yyyy-MM-dd', $inv).Date
    } catch {
        Write-Host (T 'ErrBadDate' @($BeforeDate)) -ForegroundColor Red
        exit 1
    }
    $rangeDesc = T 'RuleBefore' @($cutoff.ToString('yyyy-MM-dd'))
} else {
    if ($KeepRecentDays -lt 1) {
        Write-Host (T 'ErrDaysMin') -ForegroundColor Red
        exit 1
    }
    $cutoff = (Get-Date).Date.AddDays(-($KeepRecentDays - 1))
    $rangeDesc = T 'RuleRecent' @($cutoff.ToString('yyyy-MM-dd'), $KeepRecentDays)
}

if (-not $UseFileDate) {
    $hasDateFolder = $false
    foreach ($sub in (Get-ChildItem -LiteralPath $RootPath -Directory -ErrorAction SilentlyContinue)) {
        if ($sub.Name -match '^\d{4}-\d{2}-\d{2}' -and $null -ne (Try-ParseDatePrefix $sub.Name)) {
            $hasDateFolder = $true
            break
        }
    }
    if (-not $hasDateFolder) {
        $rawTotal = @(Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $rawExtSet.ContainsKey($_.Extension.ToLower()) }).Count
        if ($rawTotal -gt 0) {
            if (-not $DryRun -and -not $NoConfirm) {
                Write-Host ""
                Write-Host (T 'NonDateFoundNotice' @($rawTotal)) -ForegroundColor Yellow
                $switchAns = Read-Host (T 'NonDateSwitchPrompt')
                if ($null -ne $switchAns -and ($switchAns.Trim() -in @('Y', 'y'))) {
                    $UseFileDate = $true
                } else {
                    Write-Host (T 'Cancelled') -ForegroundColor Yellow
                    exit 0
                }
            } else {
                Write-Host ""
                Write-Host (T 'NonDateHintCli' @($rawTotal)) -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkCyan
Write-Host (T 'HeaderRoot'    @($RootPath))
Write-Host (T 'HeaderExts'    @($rawExtList -join ', '))
Write-Host (T 'HeaderScope'   @($(if ($UseFileDate) { T 'ScopeFileDate' } else { T 'ScopeDateFolders' })))
Write-Host (T 'HeaderRule'    @($rangeDesc))
Write-Host (T 'HeaderRating'  @($(if ($DeleteRated) { T 'RatingDelete' } else { T 'RatingKeep' }))) -ForegroundColor $(if ($DeleteRated) { 'Red' } else { 'Green' })
Write-Host (T 'HeaderRawOnly' @($(if ($DeleteRawOnly) { T 'RawOnlyDelete' } else { T 'RawOnlyKeep' }))) -ForegroundColor $(if ($DeleteRawOnly) { 'Red' } else { 'Green' })
$catLabel = if ($DeleteRated) { T 'CatSkipped' } elseif ($detectedDbLabels.Count -gt 0) { $detectedDbLabels -join '; ' } elseif ($NoCatalog) { T 'CatDisabled' } else { T 'CatNotFound' }
Write-Host (T 'HeaderCatalog' @($catLabel))
Write-Host (T 'HeaderMode'    @($(if ($DryRun) { T 'ModeDryRun' } else { T 'ModeLive' }))) -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Red' })
Write-Host "==================================================" -ForegroundColor DarkCyan

# ========== SCAN CANDIDATES ==========
$candidates = New-Object System.Collections.Generic.List[object]
$groupInfo  = @{}

if ($UseFileDate) {
    $allFiles = @(Get-ChildItem -LiteralPath $RootPath -Recurse -File)
    $byFolder = $allFiles | Group-Object DirectoryName
    $flatKey  = '__FLAT__'
    $flatName = T 'FlatBucketName'
    $groupInfo[$flatKey] = [pscustomobject]@{
        GroupKey      = $flatKey
        GroupName     = $flatName
        XmpCount      = 0
        TotalRaw      = 0
        KeptRated     = 0
        KeptUnknown   = 0
        KeptRawOnly   = 0
        TargetCount   = 0
        TargetBytes   = 0L
        TargetRawOnly = 0
    }
    foreach ($fg in $byFolder) {
        $dirFiles = @($fg.Group)
        $raws = @($dirFiles | Where-Object { $rawExtSet.ContainsKey($_.Extension.ToLower()) -and $_.LastWriteTime.Date -lt $cutoff })
        if ($raws.Count -eq 0) { continue }

        $lowerMap = @{}
        $xmpCount = 0
        foreach ($af in $dirFiles) {
            $lowerMap[$af.Name.ToLower()] = $af.FullName
            if ($af.Extension -ieq '.xmp') { $xmpCount++ }
        }
        $groupInfo[$flatKey].XmpCount += $xmpCount
        $groupInfo[$flatKey].TotalRaw += $raws.Count

        foreach ($f in $raws) {
            $baseLower = [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()
            $companions = New-Object System.Collections.Generic.List[string]
            foreach ($cext in @('.jpg', '.jpeg', '.hif', '.heic')) {
                $ck = $baseLower + $cext
                if ($lowerMap.ContainsKey($ck)) { $companions.Add($lowerMap[$ck]) }
            }
            $acrKey = $baseLower + '.acr'
            $acrPath = if ($lowerMap.ContainsKey($acrKey)) { $lowerMap[$acrKey] } else { $null }
            $scRes = Find-RawSidecars -RawPath $f.FullName -FolderFilesLower $lowerMap

            $candidates.Add([pscustomobject]@{
                GroupKey        = $flatKey
                FolderPath      = $fg.Name
                File            = $f
                BaseLower       = $baseLower
                DeleteSidecars  = $scRes.DeleteSidecars
                ReadSidecars    = $scRes.ReadSidecars
                SidecarError    = $scRes.HasError
                CompanionImages = $companions.ToArray()
                IsRawOnly       = ($companions.Count -eq 0)
                AcrPath         = $acrPath
            }) | Out-Null
        }
    }
} else {
    $dateFolders = @(Get-ChildItem -LiteralPath $RootPath -Directory | Sort-Object Name)
    foreach ($folder in $dateFolders) {
        if ($folder.Name -match '^\d{4}-\d{2}-\d{2}') {
            $fd = Try-ParseDatePrefix $folder.Name
            if ($null -eq $fd) {
                Write-Host (T 'WarnInvalidDateFolder' @($folder.Name)) -ForegroundColor Yellow
                continue
            }
        } else {
            continue
        }
        if ($fd -ge $cutoff) { continue }

        $allFiles = @(Get-ChildItem -LiteralPath $folder.FullName -Recurse -File)
        $subGroups = @($allFiles | Group-Object DirectoryName)
        $dateRawCount = 0
        $dateXmpCount = 0
        $dateCandidates = New-Object System.Collections.Generic.List[object]

        foreach ($sg in $subGroups) {
            $subFiles = @($sg.Group)
            $raws = @($subFiles | Where-Object { $rawExtSet.ContainsKey($_.Extension.ToLower()) })
            if ($raws.Count -eq 0) { continue }

            $lowerMap = @{}
            $xmpCount = 0
            foreach ($af in $subFiles) {
                $lowerMap[$af.Name.ToLower()] = $af.FullName
                if ($af.Extension -ieq '.xmp') { $xmpCount++ }
            }
            $dateRawCount += $raws.Count
            $dateXmpCount += $xmpCount

            foreach ($f in $raws) {
                $baseLower = [IO.Path]::GetFileNameWithoutExtension($f.Name).ToLower()
                $companions = New-Object System.Collections.Generic.List[string]
                foreach ($cext in @('.jpg', '.jpeg', '.hif', '.heic')) {
                    $ck = $baseLower + $cext
                    if ($lowerMap.ContainsKey($ck)) { $companions.Add($lowerMap[$ck]) }
                }
                $acrKey = $baseLower + '.acr'
                $acrPath = if ($lowerMap.ContainsKey($acrKey)) { $lowerMap[$acrKey] } else { $null }
                $scRes = Find-RawSidecars -RawPath $f.FullName -FolderFilesLower $lowerMap

                $dateCandidates.Add([pscustomobject]@{
                    GroupKey        = $folder.FullName
                    FolderPath      = $sg.Name
                    File            = $f
                    BaseLower       = $baseLower
                    DeleteSidecars  = $scRes.DeleteSidecars
                    ReadSidecars    = $scRes.ReadSidecars
                    SidecarError    = $scRes.HasError
                    CompanionImages = $companions.ToArray()
                    IsRawOnly       = ($companions.Count -eq 0)
                    AcrPath         = $acrPath
                }) | Out-Null
            }
        }
        if ($dateRawCount -eq 0) { continue }

        $groupInfo[$folder.FullName] = [pscustomobject]@{
            GroupKey      = $folder.FullName
            GroupName     = $folder.Name
            XmpCount      = $dateXmpCount
            TotalRaw      = $dateRawCount
            KeptRated     = 0
            KeptUnknown   = 0
            KeptRawOnly   = 0
            TargetCount   = 0
            TargetBytes   = 0L
            TargetRawOnly = 0
        }
        foreach ($dc in $dateCandidates) { $candidates.Add($dc) | Out-Null }
    }
}

# ========== DETECT STAR RATINGS ==========
$exifMap      = @{}
$catMap       = @{}
$loadedDbCnt  = 0

if (-not $DeleteRated -and $candidates.Count -gt 0) {
    if (-not $NoCatalog -and ($detectedDbLabels.Count -gt 0)) {
        Write-Host (T 'StatusReadingCatalog') -ForegroundColor DarkGray
        try {
            $dbRes = Get-AllSoftwareRatingMap -PhotoRoot $RootPath -ExplicitCatalogPath $(if ($explicitCatalog) { $CatalogPath } else { $null }) -PixCakeDbRoot $PixCakeDbRoot -ProjectRoot $projectRoot -ScriptDir $scriptDir
            if ($dbRes.LockWarnings.Count -gt 0) {
                Write-Host ""
                Write-Host (T 'WarnLrRunning1') -ForegroundColor Red
                Write-Host (T 'WarnLrRunning2') -ForegroundColor Red
            }
            $catMap = $dbRes.Ratings
            $loadedDbCnt = $dbRes.Labels.Count
            Write-Host (T 'StatusLoadedCatalog' @($catMap.Count)) -ForegroundColor DarkGray
            foreach ($dt in $dbRes.Details) { Write-Host $dt -ForegroundColor DarkGray }
        } catch {
            Write-Host ("[ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
            Write-Host (T 'ErrCatalogAbort') -ForegroundColor Red
            exit 1
        }
    }
    $needExif = New-Object System.Collections.Generic.List[object]
    foreach ($c in $candidates) {
        if (-not $DeleteRawOnly -and $c.IsRawOnly) { continue }
        $catKey = $c.FolderPath.TrimEnd('\', '/').ToLower() + '|' + $c.BaseLower
        if (-not ($catMap.ContainsKey($catKey) -and $catMap[$catKey] -ge 1)) {
            $needExif.Add($c)
        }
    }
    if ($needExif.Count -gt 0) {
        $exifMap = Get-RawRatingMap -Candidates ($needExif.ToArray()) -ExifTool $ExifToolPath
    }
}

$targets        = New-Object System.Collections.Generic.List[object]
$skippedRated   = 0
$skippedUnknown = 0
$skippedRawOnly = 0
$keptByCatHit   = 0

foreach ($c in $candidates) {
    $fp    = $c.File.FullName
    $gStat = $groupInfo[$c.GroupKey]

    $catKey = $c.FolderPath.TrimEnd('\', '/').ToLower() + '|' + $c.BaseLower
    $cr = if (-not $DeleteRated -and $catMap.ContainsKey($catKey)) { $catMap[$catKey] } else { 0 }
    if (-not $DeleteRated -and $cr -ge 1) {
        $skippedRated++
        $gStat.KeptRated++
        $keptByCatHit++
        continue
    }
    if (-not $DeleteRawOnly -and $c.IsRawOnly) {
        $skippedRawOnly++
        $gStat.KeptRawOnly++
        continue
    }
    if (-not $DeleteRated) {
        $er = if ($exifMap.ContainsKey($fp)) { $exifMap[$fp] } else { -1 }
        $rt = Merge-Rating $er $cr
        if ($rt -ge 1) {
            $skippedRated++
            $gStat.KeptRated++
            continue
        }
        if ($rt -eq -1) {
            $skippedUnknown++
            $gStat.KeptUnknown++
            continue
        }
    }
    $targets.Add($c) | Out-Null

    $gStat.TargetCount++
    $gStat.TargetBytes += $c.File.Length
    if ($c.IsRawOnly) { $gStat.TargetRawOnly++ }
}

if ($targets.Count -eq 0) {
    if ($candidates.Count -gt 0) {
        $msgColor = if ($skippedUnknown -gt 0) { 'Yellow' } else { 'Green' }
        Write-Host (T 'NothingAllKept' @($candidates.Count, $skippedRated, $skippedUnknown, $skippedRawOnly)) -ForegroundColor $msgColor
    } else {
        Write-Host (T 'NothingFound') -ForegroundColor Green
    }
    exit 0
}

# ========== PREVIEW & SAFETY WARNINGS ==========
$totalBytes         = 0L
$targetSidecarCount = 0
$targetAcrCount     = 0
$targetRawOnlyTotal = 0
foreach ($t in $targets) {
    $totalBytes += $t.File.Length
    $targetSidecarCount += $t.DeleteSidecars.Count
    if ($t.AcrPath)   { $targetAcrCount++ }
    if ($t.IsRawOnly) { $targetRawOnlyTotal++ }
}

$affectedGroups = @($groupInfo.Values | Where-Object { $_.TargetCount -gt 0 } | Sort-Object GroupName)
$olderKeptRated    = 0
$affectedKeptRated = 0
foreach ($gv in $groupInfo.Values) {
    if ($gv.TargetCount -gt 0) { $affectedKeptRated += $gv.KeptRated }
    else { $olderKeptRated += $gv.KeptRated }
}

$noXmpZeroRatedGroups = @($affectedGroups | Where-Object { $_.XmpCount -eq 0 -and $_.KeptRated -eq 0 })

Write-Host ""
Write-Host (T 'PreviewHeader' @($affectedGroups.Count, $targets.Count)) -ForegroundColor Cyan
foreach ($gv in $affectedGroups) {
    $flags = New-Object System.Collections.Generic.List[string]
    if ($gv.XmpCount -eq 0 -and $gv.KeptRated -eq 0) { $flags.Add((T 'FlagNoXmpZero')) }
    elseif ($gv.XmpCount -eq 0) { $flags.Add((T 'FlagNoXmp')) }
    if ($gv.KeptRawOnly -gt 0)   { $flags.Add((T 'FlagKeepRawOnly' @($gv.KeptRawOnly))) }
    if ($gv.TargetRawOnly -gt 0) { $flags.Add((T 'FlagDelRawOnly'  @($gv.TargetRawOnly))) }
    $flagStr = if ($flags.Count -gt 0) { "  [" + ($flags -join ', ') + "]" } else { "" }
    $keptGroupTotal = $gv.KeptRated + $gv.KeptUnknown + $gv.KeptRawOnly
    $lineColor = if ($gv.XmpCount -eq 0 -and $gv.KeptRated -eq 0 -and -not $CatalogPath -and -not $DeleteRated) { 'Red' } else { 'Gray' }
    Write-Host (T 'PreviewLine' @($gv.GroupName, $gv.TargetCount, $keptGroupTotal, (Format-Size $gv.TargetBytes), $flagStr)) -ForegroundColor $lineColor
}
$extGroups = @($targets | Group-Object { $_.File.Extension.ToLower() } | Sort-Object @{ Expression = 'Count'; Descending = $true }, Name)
$fmtSummary = ($extGroups | ForEach-Object { "{0} ({1})" -f $_.Name, $_.Count }) -join ', '
Write-Host (T 'PreviewTotalSize' @((Format-Size $totalBytes))) -ForegroundColor Cyan
Write-Host (T 'PreviewFormats'   @($fmtSummary))               -ForegroundColor Cyan
if ($targetSidecarCount -gt 0) { Write-Host (T 'PreviewSidecars'    @($targetSidecarCount)) -ForegroundColor Cyan }
if ($targetAcrCount -gt 0)     { Write-Host (T 'PreviewAcrs'        @($targetAcrCount))     -ForegroundColor Cyan }
if ($skippedRated -gt 0)       { Write-Host (T 'PreviewKeptRated'   @($skippedRated, $affectedKeptRated, $olderKeptRated, $keptByCatHit)) -ForegroundColor Yellow }
if ($skippedUnknown -gt 0)     { Write-Host (T 'PreviewKeptUnknown' @($skippedUnknown))     -ForegroundColor Yellow }
if ($skippedRawOnly -gt 0)     { Write-Host (T 'PreviewKeptRawOnly' @($skippedRawOnly))     -ForegroundColor Yellow }

$rootTrim = $RootPath.TrimEnd('\', '/')
$formatTargetLine = {
    param($Item)
    $rel = if ($Item.File.FullName.StartsWith($rootTrim + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $Item.File.FullName.Substring($rootTrim.Length + 1)
    } else {
        $Item.File.Name
    }
    $extra = New-Object System.Collections.Generic.List[string]
    if ($Item.DeleteSidecars.Count -gt 0) { $extra.Add('+xmp') }
    if ($Item.AcrPath) { $extra.Add('+acr') }
    $exStr = if ($extra.Count -gt 0) { ' ' + ($extra -join ' ') } else { '' }
    "    {0}  ({1}{2})" -f $rel, (Format-Size $Item.File.Length), $exStr
}

$sampleN = [Math]::Min(10, $targets.Count)
Write-Host (T 'PreviewSampleHeader' @($sampleN, $targets.Count)) -ForegroundColor Cyan
for ($idx = 0; $idx -lt $sampleN; $idx++) {
    Write-Host (& $formatTargetLine $targets[$idx]) -ForegroundColor Gray
}
if ($targets.Count -gt 10) {
    Write-Host (T 'PreviewSampleMore' @($targets.Count - 10)) -ForegroundColor DarkGray
}

if (-not $DeleteRated -and ($loadedDbCnt -eq 0) -and $noXmpZeroRatedGroups.Count -gt 0) {
    Write-Host ""
    Write-Host (T 'WarnNoXmp1' @($noXmpZeroRatedGroups.Count)) -ForegroundColor Red
    Write-Host (T 'WarnNoXmp2') -ForegroundColor Red
}
if ($targetRawOnlyTotal -gt 0) {
    Write-Host (T 'WarnDeleteRawOnly' @($targetRawOnlyTotal)) -ForegroundColor Yellow
}
if ($totalBytes -ge 20GB) {
    Write-Host (T 'TipLargeRecycle' @((Format-Size $totalBytes))) -ForegroundColor Yellow
}

# ========== CONFIRMATION GATE ==========
if (-not $DryRun -and -not $NoConfirm) {
    Write-Host ""
    Write-Host (T 'ConfirmNote') -ForegroundColor Yellow
    while ($true) {
        $ansRaw = Read-Host (T 'ConfirmPrompt')
        if ($null -eq $ansRaw) {
            Write-Host (T 'Cancelled') -ForegroundColor Yellow
            exit 0
        }
        $ans = $ansRaw.Trim()
        if ($ans -in @('V', 'v')) {
            Write-Host ""
            Write-Host (T 'PreviewAllHeader' @($targets.Count)) -ForegroundColor Cyan
            for ($idx = 0; $idx -lt $targets.Count; $idx++) {
                $lineText = (& $formatTargetLine $targets[$idx]).TrimStart()
                Write-Host ("  [{0}/{1}] {2}" -f ($idx + 1), $targets.Count, $lineText) -ForegroundColor Gray
            }
            Write-Host (T 'PreviewAllEnd') -ForegroundColor Cyan
            Write-Host ""
            continue
        }
        if ($ans -in @('Y', 'y')) { break }
        Write-Host (T 'Cancelled') -ForegroundColor Yellow
        exit 0
    }
}

$logBase = if ($projectRoot) { $projectRoot } else { $RootPath }
$logDir  = Join-Path $logBase 'logs'
try {
    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logPath = Join-Path $logDir ("raw_cleanup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
} catch {
    $logPath = Join-Path $logBase ("raw_cleanup_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
}

$logLines = New-Object System.Collections.Generic.List[string]
$logLines.Add("# RAW cleanup log  generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$logLines.Add("# Root: $RootPath")
$logLines.Add("# Extensions: $($rawExtList -join ', ')")
$logLines.Add("# Rule: $rangeDesc")
$logLines.Add("# Mode: $(if ($DryRun) {'DryRun'} else {'LIVE'})")
$logLines.Add("# Catalog: $(if ($CatalogPath -and -not $DeleteRated) {$CatalogPath} else {'none'})")
$logLines.Add("# Files: $($targets.Count)  size: $(Format-Size $totalBytes)")
$logLines.Add("# Policy: deleteRated=$DeleteRated  deleteRawOnly=$DeleteRawOnly  keptRated=$skippedRated  keptUnknown=$skippedUnknown  keptRawOnly=$skippedRawOnly")
$logLines.Add("# ----")

$ok = 0; $fail = 0; $freed = 0L; $failList = New-Object System.Collections.Generic.List[string]
$i = 0
$progTitle = T 'ProgressActivity'
foreach ($t in $targets) {
    $i++
    $p = $t.File.FullName
    Write-Progress -Activity $progTitle -Status $t.File.Name -PercentComplete ([int]($i * 100 / $targets.Count))
    if ($DryRun) {
        $logLines.Add("[DRY-RUN] would delete: $p")
        foreach ($sc in $t.DeleteSidecars) { $logLines.Add("[DRY-RUN] would delete sidecar: $sc") }
        if ($t.AcrPath) { $logLines.Add("[DRY-RUN] would delete acr: $($t.AcrPath)") }
        $ok++
        continue
    }
    try {
        $len = $t.File.Length
        Move-ToRecycleBin -Path $p
        $freed += $len; $ok++
        $logLines.Add("[OK]   recycled: $p")
        foreach ($sc in $t.DeleteSidecars) {
            try {
                Move-ToRecycleBin -Path $sc
                $logLines.Add("[OK]   recycled sidecar: $sc")
            } catch {
                $logLines.Add("[WARN] sidecar recycle failed: $sc -> $($_.Exception.Message)")
            }
        }
        if ($t.AcrPath) {
            try {
                Move-ToRecycleBin -Path $t.AcrPath
                $logLines.Add("[OK]   recycled acr: $($t.AcrPath)")
            } catch {
                $logLines.Add("[WARN] acr recycle failed: $($t.AcrPath) -> $($_.Exception.Message)")
            }
        }
    } catch {
        $fail++
        $failList.Add("$p  ->  $($_.Exception.Message)")
        $logLines.Add("[FAIL] $p  ->  $($_.Exception.Message)")
    }
}
Write-Progress -Activity $progTitle -Completed

try {
    $logLines | Out-File -LiteralPath $logPath -Encoding UTF8
} catch {
    Write-Host (T 'WarnWriteLog' @($logPath, $_.Exception.Message)) -ForegroundColor Yellow
}

Write-Host ""
Write-Host (T 'DoneHeader') -ForegroundColor Green
if ($DryRun) {
    Write-Host (T 'DoneDrySummary' @($ok, (Format-Size $totalBytes))) -ForegroundColor Yellow
    if ($skippedRated -gt 0)   { Write-Host (T 'DoneDryKeptRated'   @($skippedRated))   -ForegroundColor Yellow }
    if ($skippedUnknown -gt 0) { Write-Host (T 'DoneDryKeptUnknown' @($skippedUnknown)) -ForegroundColor Yellow }
    if ($skippedRawOnly -gt 0) { Write-Host (T 'DoneDryKeptRawOnly' @($skippedRawOnly)) -ForegroundColor Yellow }
    Write-Host (T 'DoneDryHint') -ForegroundColor Yellow
} else {
    Write-Host (T 'DoneLiveSummary' @($ok, (Format-Size $freed))) -ForegroundColor Green
    if ($skippedRated -gt 0)   { Write-Host (T 'DoneLiveKeptRated'   @($skippedRated))   -ForegroundColor Yellow }
    if ($skippedUnknown -gt 0) { Write-Host (T 'DoneLiveKeptUnknown' @($skippedUnknown)) -ForegroundColor Yellow }
    if ($skippedRawOnly -gt 0) { Write-Host (T 'DoneLiveKeptRawOnly' @($skippedRawOnly)) -ForegroundColor Yellow }
    if ($fail -gt 0) {
        Write-Host (T 'DoneFailed' @($fail)) -ForegroundColor Red
        $failList | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
}
Write-Host (T 'DoneLogPath' @($logPath)) -ForegroundColor DarkGray

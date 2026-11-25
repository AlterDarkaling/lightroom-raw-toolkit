<#
.SYNOPSIS
  Restore Lightroom star ratings (and pick flags) into matching JPG files or .xmp sidecars.
  Matches strictly by (folder path + base filename) so identical filenames across
  different folders never cross-contaminate. Skips already-matching files by default,
  preserves file modification timestamps (-P), and stores original backups outside the
  photo tree under <ProjectRoot>\backups\ so cloud drives never sync .jpg_original files.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]$JpgRoot,
    [string]$CatalogPath,
    [switch]$NoCatalog,
    [string]$PixCakeDbRoot,
    [ValidateSet('auto', 'db', 'files')]
    [string]$RatingSource = 'auto',
    [string]$ExifToolPath,
    [int]$RecentDays,
    [string]$SubFolder,
    [switch]$SidecarOnly,
    [switch]$Force,
    [switch]$NoBackup,
    [string]$BackupDir,
    [switch]$DryRun,
    [switch]$NoConfirm,
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

$hasRecentDaysParam = $PSBoundParameters.ContainsKey('RecentDays')
if ($hasRecentDaysParam -and $RecentDays -lt 1) {
    Write-Host (T 'ErrDaysMin') -ForegroundColor Red
    exit 1
}

if (-not $JpgRoot) {
    $JpgRoot = Resolve-DefaultPhotoRoot -ScriptDir $scriptDir -AllowJpg $true
}
if (-not (Test-Path -LiteralPath $JpgRoot -PathType Container)) {
    Write-Host (T 'ErrNoJpgRoot' @($JpgRoot)) -ForegroundColor Red
    exit 1
}
$JpgRoot = (Resolve-Path -LiteralPath $JpgRoot).Path.TrimEnd('\', '/')

$explicitCatalog = [bool]$CatalogPath
if ($explicitCatalog) {
    if (-not (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
        Write-Host (T 'ErrNoCatalog' @($CatalogPath)) -ForegroundColor Red
        exit 1
    }
    $CatalogPath = (Resolve-Path -LiteralPath $CatalogPath).Path
} elseif ($NoCatalog) {
    $CatalogPath = $null
}

$ExifToolPath = Resolve-ExifToolPath -ExplicitPath $ExifToolPath -ProjectRoot $projectRoot -ScriptDir $scriptDir
if (-not $ExifToolPath -or -not (Test-Path -LiteralPath $ExifToolPath -PathType Leaf)) {
    Write-Host (T 'ErrNoExifToolJpg') -ForegroundColor Red
    exit 1
}
$ExifToolPath = (Resolve-Path -LiteralPath $ExifToolPath).Path

$useSidecar = $SidecarOnly.IsPresent
if (-not $DryRun.IsPresent -and -not $NoConfirm.IsPresent) {
    if (-not $SidecarOnly.IsPresent) {
        Write-Host ""
        Write-Host (T 'JpgPromptTarget') -ForegroundColor Cyan
        $modeChoice = Read-Host (T 'PromptChoice')
        if ($null -eq $modeChoice) { Write-Host (T 'JpgCancelled') -ForegroundColor Yellow; exit 0 }
        $modeChoice = $modeChoice.Trim()
        if (-not $modeChoice -or $modeChoice -eq '0') {
            Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
            exit 0
        } elseif ($modeChoice -eq '1') {
            $useSidecar = $false
        } elseif ($modeChoice -eq '2') {
            $useSidecar = $true
        } else {
            Write-Host (T 'ErrInvalidChoice' @($modeChoice)) -ForegroundColor Red
            exit 1
        }
    }

    if (-not $hasRecentDaysParam -and -not $SubFolder) {
        Write-Host ""
        Write-Host (T 'JpgPromptScope') -ForegroundColor Cyan
        $scopeChoice = Read-Host (T 'PromptChoice')
        if ($null -eq $scopeChoice) { Write-Host (T 'JpgCancelled') -ForegroundColor Yellow; exit 0 }
        $scopeChoice = $scopeChoice.Trim()
        if (-not $scopeChoice -or $scopeChoice -eq '0') {
            Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
            exit 0
        } elseif ($scopeChoice -eq '1') {
            # all folders
        } elseif ($scopeChoice -eq '2') {
            $dRaw = Read-Host (T 'JpgPromptRecentDays')
            if ($null -eq $dRaw) { Write-Host (T 'JpgCancelled') -ForegroundColor Yellow; exit 0 }
            $dRaw = $dRaw.Trim()
            if (-not $dRaw -or $dRaw -eq '0') {
                Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
                exit 0
            }
            $dNum = 0
            if (-not [int]::TryParse($dRaw, [ref]$dNum)) {
                Write-Host (T 'ErrInvalidDays' @($dRaw)) -ForegroundColor Red
                exit 1
            }
            if ($dNum -lt 1) {
                Write-Host (T 'ErrDaysMin') -ForegroundColor Red
                exit 1
            }
            $RecentDays = $dNum
        } elseif ($scopeChoice -eq '3') {
            $sfRaw = Read-Host (T 'JpgPromptSubFolder')
            if ($null -eq $sfRaw) { Write-Host (T 'JpgCancelled') -ForegroundColor Yellow; exit 0 }
            $sfRaw = $sfRaw.Trim().Trim('"')
            if (-not $sfRaw -or $sfRaw -eq '0') {
                Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
                exit 0
            }
            $SubFolder = $sfRaw
        } else {
            Write-Host (T 'ErrInvalidScopeChoice' @($scopeChoice)) -ForegroundColor Red
            exit 1
        }
    }
}

$scanRoot = $JpgRoot
$scopeDesc = T 'JpgScopeAll'
$recentCutoff = $null
if ($SubFolder) {
    $candSub = if ([IO.Path]::IsPathRooted($SubFolder)) { $SubFolder } else { Join-Path $JpgRoot $SubFolder }
    if (-not (Test-Path -LiteralPath $candSub -PathType Container)) {
        Write-Host (T 'ErrNoSubFolder' @($candSub)) -ForegroundColor Red
        exit 1
    }
    $scanRoot = (Resolve-Path -LiteralPath $candSub).Path.TrimEnd('\', '/')
    $subLabel = if ($scanRoot -ieq $JpgRoot) {
        '.'
    } elseif ($scanRoot.StartsWith($JpgRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $scanRoot.Substring($JpgRoot.Length + 1)
    } else {
        $scanRoot
    }
    $scopeDesc = T 'JpgScopeSubFolder' @($subLabel)
}
if ($RecentDays -ge 1) {
    $recentCutoff = (Get-Date).Date.AddDays(-($RecentDays - 1))
    $recentDesc = T 'JpgScopeRecent' @($RecentDays, $recentCutoff.ToString('yyyy-MM-dd'))
    $scopeDesc = if ($SubFolder) { "$scopeDesc, $recentDesc" } else { $recentDesc }
}

$effectiveBackupDir = $null
if (-not $useSidecar -and -not $NoBackup.IsPresent) {
    $effectiveBackupDir = if ($BackupDir) {
        $BackupDir
    } else {
        Join-Path $projectRoot ("backups\jpg_restore_{0}" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    }
}

$sourceDesc = switch ($RatingSource) {
    'db'    { T 'JpgSourceDbOnly' }
    'files' { T 'JpgSourceFilesOnly' }
    default { T 'JpgSourceAuto' }
}

Write-Host ""
Write-Host (T 'JpgBanner') -ForegroundColor Cyan
Write-Host (T 'JpgRoot'      @($JpgRoot))
Write-Host (T 'JpgScopeLine' @($scopeDesc))
Write-Host (T 'JpgSourceLine'@($sourceDesc))
Write-Host (T 'JpgExifTool'  @($ExifToolPath))
if ($DryRun.IsPresent) {
    Write-Host (T 'JpgModeDry') -ForegroundColor Yellow
} elseif ($useSidecar) {
    Write-Host (T 'JpgModeLiveSidecar') -ForegroundColor Green
} elseif ($NoBackup.IsPresent) {
    Write-Host (T 'JpgModeLiveJpgNoBackup') -ForegroundColor Red
} else {
    Write-Host (T 'JpgModeLiveJpgBackup' @($effectiveBackupDir)) -ForegroundColor Yellow
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$jpgs = @(Get-ChildItem -LiteralPath $scanRoot -Recurse -File | Where-Object {
    $_.Extension -ieq '.jpg' -or $_.Extension -ieq '.jpeg'
})

if ($recentCutoff) {
    $jpgs = @($jpgs | Where-Object {
        $dirDt = Try-ParseDatePrefix $_.Directory.Name
        if ($null -eq $dirDt -and $_.DirectoryName.TrimEnd('\', '/').StartsWith($JpgRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
            $relSeg = $_.DirectoryName.TrimEnd('\', '/').Substring($JpgRoot.Length + 1).Split([char[]]@('\', '/'))[0]
            $dirDt = Try-ParseDatePrefix $relSeg
        }
        if ($null -ne $dirDt) {
            $dirDt -ge $recentCutoff
        } else {
            $_.LastWriteTime.Date -ge $recentCutoff
        }
    })
}

if ($jpgs.Count -eq 0) {
    Write-Host (T 'JpgNoFiles' @($scanRoot)) -ForegroundColor Yellow
    exit 0
}

Write-Host (T 'JpgFoundFiles' @($jpgs.Count)) -ForegroundColor DarkGray
Write-Host (T 'JpgReadingCat') -ForegroundColor DarkGray

$ratings   = @{}
$dbLabels  = @()
$filterExts = @('jpg', 'jpeg') + @((Get-DefaultRawExtensions) | ForEach-Object { $_.TrimStart('.') })
if (-not $NoCatalog.IsPresent -and $RatingSource -ne 'files') {
    try {
        $dbRes = Get-AllSoftwareRatingMap -PhotoRoot $JpgRoot -ExplicitCatalogPath $(if ($explicitCatalog) { $CatalogPath } else { $null }) -PixCakeDbRoot $PixCakeDbRoot -ExtensionFilter $filterExts -ProjectRoot $projectRoot -ScriptDir $scriptDir
        if ($dbRes.LockWarnings.Count -gt 0) {
            Write-Host (T 'WarnLrRunning1') -ForegroundColor Red
            Write-Host (T 'WarnLrRunning2') -ForegroundColor Red
            Write-Host ""
        }
        $ratings  = $dbRes.Ratings
        $dbLabels = $dbRes.Labels
        foreach ($dt in $dbRes.Details) { Write-Host $dt -ForegroundColor DarkGray }
    } catch {
        Write-Host ("[ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
        exit 1
    }
}
$catalogLabelText = if ($dbLabels.Count -gt 0) { $dbLabels -join '; ' } else { T 'JpgDbNone' }
Write-Host (T 'JpgCatalog' @($catalogLabelText)) -ForegroundColor DarkGray

# Fill missing entries from companion RAW / .xmp files (Sony IED, Bridge, Camera Raw, Capture One XMP, etc.)
if ($RatingSource -ne 'db') {
    $rawExts = Get-DefaultRawExtensions
    $compExtSet = @{}
    foreach ($re in $rawExts) { $compExtSet[$re] = $true }
    foreach ($ie in @('.hif', '.heic')) { $compExtSet[$ie] = $true }

    $compFilesToScan = New-Object System.Collections.Generic.List[string]
    $compSeen        = @{}
    $folderFilesMap  = @{}

    foreach ($jpg in $jpgs) {
        $dirTrim   = $jpg.DirectoryName.TrimEnd('\', '/')
        $dirLower  = $dirTrim.ToLower()
        $baseName  = [System.IO.Path]::GetFileNameWithoutExtension($jpg.Name)
        $baseLower = $baseName.ToLower()
        $key       = $dirLower + '|' + $baseLower
        if ($ratings.ContainsKey($key) -and $ratings[$key] -ge 1) { continue }

        if (-not $folderFilesMap.ContainsKey($dirLower)) {
            $mapInDir = @{}
            foreach ($f in (Get-ChildItem -LiteralPath $jpg.DirectoryName -File -ErrorAction SilentlyContinue)) {
                $mapInDir[$f.Name.ToLower()] = $f.FullName
            }
            $folderFilesMap[$dirLower] = $mapInDir
        }
        $dirMap = $folderFilesMap[$dirLower]

        foreach ($ce in $compExtSet.Keys) {
            $ck = $baseLower + $ce
            if ($dirMap.ContainsKey($ck)) {
                $p = $dirMap[$ck]
                if (-not $compSeen.ContainsKey($p)) { $compSeen[$p] = $true; $compFilesToScan.Add($p) }
                $rx = $ck + '.xmp'
                if ($dirMap.ContainsKey($rx)) {
                    $xp = $dirMap[$rx]
                    if (-not $compSeen.ContainsKey($xp)) { $compSeen[$xp] = $true; $compFilesToScan.Add($xp) }
                }
            }
        }
        $bx = $baseLower + '.xmp'
        if ($dirMap.ContainsKey($bx)) {
            $xp = $dirMap[$bx]
            $allowXmp = $true
            if ($useSidecar) {
                $belongsJpg = Test-SidecarBelongsToJpg -XmpPath $xp -JpgPath $jpg.FullName -DirFileSet $dirMap
                if ($belongsJpg -eq $true) { $allowXmp = $false }
            }
            if ($allowXmp -and -not $compSeen.ContainsKey($xp)) {
                $compSeen[$xp] = $true
                $compFilesToScan.Add($xp)
            }
        }
    }

    if ($compFilesToScan.Count -gt 0) {
        Write-Host (T 'JpgReadingRawXmp' @($compFilesToScan.Count)) -ForegroundColor DarkGray
        $compMap = Get-FileRatingMap -FilePaths ($compFilesToScan.ToArray()) -ExifTool $ExifToolPath
        foreach ($fp in $compMap.Keys) {
            $r = [int]$compMap[$fp]
            if ($r -lt 1) { continue }
            $fDirLower = ([IO.Path]::GetDirectoryName($fp)).TrimEnd('\', '/').ToLower()
            $fn        = [IO.Path]::GetFileName($fp)
            $stem      = [IO.Path]::GetFileNameWithoutExtension($fn)
            if ([IO.Path]::GetExtension($fn) -ieq '.xmp') {
                $stemExt = [IO.Path]::GetExtension($stem).ToLower()
                if ($stemExt -and $compExtSet.ContainsKey($stemExt)) {
                    $stem = [IO.Path]::GetFileNameWithoutExtension($stem)
                }
            }
            $ckey = $fDirLower + '|' + $stem.ToLower()
            $ratings[$ckey] = Merge-Rating $ratings[$ckey] $r
        }
    }
}

Write-Host (T 'JpgLoadedCat' @($ratings.Count)) -ForegroundColor Magenta

if ($ratings.Count -eq 0) {
    Write-Host (T 'JpgNoRatings') -ForegroundColor Yellow
    exit 0
}

$matchedItems = New-Object System.Collections.Generic.List[object]
$inspectList  = New-Object System.Collections.Generic.List[string]
$dirFileSets  = @{}
$noRating     = 0

foreach ($jpg in $jpgs) {
    $dirTrim   = $jpg.DirectoryName.TrimEnd('\', '/')
    $dirLower  = $dirTrim.ToLower()
    $baseName  = [System.IO.Path]::GetFileNameWithoutExtension($jpg.Name)
    $baseLower = $baseName.ToLower()
    $key       = $dirLower + '|' + $baseLower

    if (-not $ratings.ContainsKey($key)) {
        $noRating++
        continue
    }

    $targetRating = [int]$ratings[$key]
    if ($targetRating -gt 5) { $targetRating = 5 }
    if ($targetRating -lt 1) { $targetRating = 1 }

    $relDir = if ($dirTrim -ieq $JpgRoot) {
        '.'
    } elseif ($dirTrim.StartsWith($JpgRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $dirTrim.Substring($JpgRoot.Length + 1)
    } else {
        $dirTrim
    }

    $xmpPath = Join-Path $jpg.DirectoryName ($baseName + '.xmp')
    $xmpExists = $false
    $xmpBelongsToJpg = $true
    if ($useSidecar) {
        $xmpExists = Test-Path -LiteralPath $xmpPath -PathType Leaf
        if ($xmpExists) {
            if (-not $dirFileSets.ContainsKey($dirLower)) {
                $set = @{}
                foreach ($f in (Get-ChildItem -LiteralPath $jpg.DirectoryName -File -ErrorAction SilentlyContinue)) {
                    $set[$f.Name.ToLower()] = $true
                }
                $dirFileSets[$dirLower] = $set
            }
            $xmpBelongsToJpg = Test-SidecarBelongsToJpg -XmpPath $xmpPath -JpgPath $jpg.FullName -DirFileSet $dirFileSets[$dirLower]
            if ($xmpBelongsToJpg -eq $true) {
                $inspectList.Add($xmpPath)
            }
        }
    }

    $inspectList.Add($jpg.FullName)
    $matchedItems.Add([PSCustomObject]@{
        File            = $jpg
        TargetRating    = $targetRating
        RelDir          = $relDir
        XmpPath         = $xmpPath
        XmpExists       = $xmpExists
        XmpBelongsToJpg = $xmpBelongsToJpg
        Status          = ''
    })
}

if ($matchedItems.Count -eq 0) {
    Write-Host (T 'JpgSummaryHeader') -ForegroundColor Cyan
    Write-Host (T 'JpgSummaryCounts' @(0, 0, 0, $noRating, 0))
    exit 0
}

Write-Host (T 'JpgScanningExisting' @($matchedItems.Count)) -ForegroundColor DarkGray
$existingRatings = Get-FileRatingMap -FilePaths ($inspectList.ToArray()) -ExifTool $ExifToolPath

$totalNew       = 0
$totalUpdate    = 0
$totalSkipSame  = 0
$totalConflict  = 0
$totalUnread    = 0
$dirStats       = @{}

foreach ($item in $matchedItems) {
    $curJpgRating = if ($existingRatings.ContainsKey($item.File.FullName)) { [int]$existingRatings[$item.File.FullName] } else { -1 }

    if ($useSidecar) {
        if ($item.XmpExists) {
            if ($null -eq $item.XmpBelongsToJpg) {
                $item.Status = 'unreadable'
            } elseif ($item.XmpBelongsToJpg -eq $false) {
                $item.Status = 'conflict'
            } else {
                $curXmpRating = if ($existingRatings.ContainsKey($item.XmpPath)) { [int]$existingRatings[$item.XmpPath] } else { -1 }
                if ($curXmpRating -lt 0 -and -not $Force.IsPresent) {
                    $item.Status = 'unreadable'
                } elseif ($curXmpRating -eq $item.TargetRating -and -not $Force.IsPresent) {
                    $item.Status = 'skip_same'
                } elseif ($curXmpRating -le 0) {
                    $item.Status = 'new'
                } else {
                    $item.Status = 'update'
                }
            }
        } else {
            if ($curJpgRating -lt 0 -and -not $Force.IsPresent) {
                $item.Status = 'unreadable'
            } elseif ($curJpgRating -eq $item.TargetRating -and -not $Force.IsPresent) {
                $item.Status = 'skip_same'
            } elseif ($curJpgRating -le 0) {
                $item.Status = 'new'
            } else {
                $item.Status = 'update'
            }
        }
    } else {
        if ($curJpgRating -lt 0 -and -not $Force.IsPresent) {
            $item.Status = 'unreadable'
        } elseif ($curJpgRating -eq $item.TargetRating -and -not $Force.IsPresent) {
            $item.Status = 'skip_same'
        } elseif ($curJpgRating -le 0) {
            $item.Status = 'new'
        } else {
            $item.Status = 'update'
        }
    }

    if (-not $dirStats.ContainsKey($item.RelDir)) {
        $dirStats[$item.RelDir] = [PSCustomObject]@{
            RelDir     = $item.RelDir
            New        = 0
            Update     = 0
            SkipSame   = 0
            Conflict   = 0
            Unreadable = 0
        }
    }
    $ds = $dirStats[$item.RelDir]
    switch ($item.Status) {
        'new'        { $totalNew++;      $ds.New++ }
        'update'     { $totalUpdate++;   $ds.Update++ }
        'skip_same'  { $totalSkipSame++; $ds.SkipSame++ }
        'conflict'   { $totalConflict++; $ds.Conflict++ }
        'unreadable' { $totalUnread++;   $ds.Unreadable++ }
    }
}

$totalToWrite  = $totalNew + $totalUpdate
$totalSafeSkip = $totalConflict + $totalUnread

Write-Host ""
if ($totalToWrite -eq 0) {
    Write-Host (T 'JpgNothingToWrite' @($matchedItems.Count, $totalSkipSame, $noRating)) -ForegroundColor Green
    if ($totalSafeSkip -gt 0) {
        Write-Host (T 'JpgPreviewExtraSkips' @($totalConflict, $totalUnread)) -ForegroundColor Yellow
    }
    exit 0
}

$activeDirs  = New-Object System.Collections.Generic.List[object]
$skippedDirs = 0
$skippedDirFiles = 0
foreach ($dKey in ($dirStats.Keys | Sort-Object)) {
    $ds = $dirStats[$dKey]
    if (($ds.New + $ds.Update + $ds.Conflict + $ds.Unreadable) -gt 0) {
        $activeDirs.Add($ds)
    } else {
        $skippedDirs++
        $skippedDirFiles += $ds.SkipSame
    }
}

$padWidth = 14
foreach ($ds in $activeDirs) {
    if ($ds.RelDir.Length -gt $padWidth) {
        $padWidth = [Math]::Min(40, $ds.RelDir.Length)
    }
}

Write-Host (T 'JpgPreviewHeader' @($totalToWrite, $activeDirs.Count)) -ForegroundColor Cyan
foreach ($ds in $activeDirs) {
    $flags = New-Object System.Collections.Generic.List[string]
    if ($ds.Conflict -gt 0)   { $flags.Add((T 'JpgPreviewFlagConflict' @($ds.Conflict))) }
    if ($ds.Unreadable -gt 0) { $flags.Add((T 'JpgPreviewFlagUnread' @($ds.Unreadable))) }
    $flagStr = if ($flags.Count -gt 0) { '   [' + ($flags -join ', ') + ']' } else { '' }
    $label = if ($ds.RelDir.Length -lt $padWidth) { $ds.RelDir.PadRight($padWidth) } else { $ds.RelDir }
    Write-Host (T 'JpgPreviewLine' @($label, $ds.New, $ds.Update, $ds.SkipSame, $flagStr))
}
if ($skippedDirs -gt 0) {
    Write-Host (T 'JpgPreviewSkippedDirs' @($skippedDirs, $skippedDirFiles)) -ForegroundColor DarkGray
}
Write-Host (T 'JpgPreviewTotals' @($totalToWrite, $totalNew, $totalUpdate, $totalSkipSame, $noRating)) -ForegroundColor Cyan
if ($totalSafeSkip -gt 0) {
    Write-Host (T 'JpgPreviewExtraSkips' @($totalConflict, $totalUnread)) -ForegroundColor Yellow
}

$previewWriteItems = @($matchedItems | Where-Object { $_.Status -eq 'new' -or $_.Status -eq 'update' })
$formatJpgSample = {
    param($Item)
    $relPath = if ($Item.RelDir -eq '.') { $Item.File.Name } else { Join-Path $Item.RelDir $Item.File.Name }
    if ($useSidecar) {
        $relPath = "{0} -> {1}" -f $relPath, ([IO.Path]::GetFileName($Item.XmpPath))
    }
    $stText = if ($Item.Status -eq 'new') { T 'JpgStatusNew' } else { T 'JpgStatusUpd' }
    T 'JpgSampleItem' @($relPath, $Item.TargetRating, $stText)
}
$jpgSampleN = [Math]::Min(10, $previewWriteItems.Count)
if ($jpgSampleN -gt 0) {
    Write-Host (T 'PreviewSampleHeader' @($jpgSampleN, $previewWriteItems.Count)) -ForegroundColor Cyan
    for ($idx = 0; $idx -lt $jpgSampleN; $idx++) {
        Write-Host (& $formatJpgSample $previewWriteItems[$idx]) -ForegroundColor Gray
    }
    if ($previewWriteItems.Count -gt 10) {
        Write-Host (T 'PreviewSampleMore' @($previewWriteItems.Count - 10)) -ForegroundColor DarkGray
    }
}

Write-Host ""
if ($useSidecar) {
    Write-Host (T 'JpgWarnSidecar1') -ForegroundColor Green
    Write-Host (T 'JpgWarnSidecar2') -ForegroundColor DarkGray
} else {
    Write-Host (T 'JpgWarnCloud1') -ForegroundColor Yellow
    Write-Host (T 'JpgWarnCloud2' @($totalToWrite, $totalSkipSame)) -ForegroundColor Yellow
    Write-Host (T 'JpgWarnCloud3') -ForegroundColor Yellow
}

$logDir   = Join-Path $projectRoot 'logs'
$logPath  = $null
$logLines = New-Object System.Collections.Generic.List[string]
$logLines.Add("# JPG star restore log  generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$logLines.Add("# Root: $JpgRoot")
$logLines.Add("# Scope: $scopeDesc")
$logLines.Add("# Target: $(if ($useSidecar) {'XMP sidecar'} else {'JPG embedded'})")
$logLines.Add("# Mode: $(if ($DryRun.IsPresent) {'DryRun'} else {'LIVE'})")
$logLines.Add("# Catalogs: $catalogLabelText")
$logLines.Add("# BackupDir: $(if ($effectiveBackupDir) {$effectiveBackupDir} else {'none'})")
$logLines.Add("# Matched: $($matchedItems.Count)  ToWrite: $totalToWrite (new=$totalNew, upd=$totalUpdate)  SkippedSame: $totalSkipSame  SafeSkip: $totalSafeSkip  NoRating: $noRating")
$logLines.Add("# ----")

foreach ($item in $matchedItems) {
    if ($item.Status -eq 'conflict') {
        $logLines.Add("[SKIP-CONFLICT] $($item.XmpPath)  target=$($item.TargetRating)star")
    } elseif ($item.Status -eq 'unreadable') {
        $logLines.Add("[SKIP-UNREADABLE] $($item.File.FullName)")
    }
}

if ($DryRun.IsPresent) {
    foreach ($item in ($matchedItems | Where-Object { $_.Status -eq 'new' -or $_.Status -eq 'update' })) {
        $dest = if ($useSidecar) { $item.XmpPath } else { $item.File.FullName }
        $logLines.Add("[DRY-RUN] $dest -> $($item.TargetRating)star ($($item.Status))")
    }
    try {
        if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $logPath = Join-Path $logDir ("jpg_restore_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $logLines | Out-File -LiteralPath $logPath -Encoding UTF8
    } catch {
        $logPath = $null
    }
    Write-Host ""
    Write-Host (T 'JpgSummaryHeader') -ForegroundColor Cyan
    Write-Host (T 'JpgSummaryCounts' @(0, $totalSkipSame, $totalSafeSkip, $noRating, 0))
    Write-Host ""
    Write-Host (T 'JpgDryDone') -ForegroundColor Yellow
    Write-Host (T 'JpgDryHint') -ForegroundColor Yellow
    if ($logPath) { Write-Host (T 'DoneLogPath' @($logPath)) -ForegroundColor DarkGray }
    exit 0
}

if (-not $NoConfirm.IsPresent) {
    Write-Host ""
    Write-Host (T 'JpgConfirmNote') -ForegroundColor Yellow
    while ($true) {
        $ansRaw = Read-Host (T 'JpgConfirmPrompt')
        if ($null -eq $ansRaw) {
            Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
            exit 0
        }
        $ans = $ansRaw.Trim()
        if ($ans -in @('V', 'v')) {
            Write-Host ""
            Write-Host (T 'PreviewAllHeader' @($previewWriteItems.Count)) -ForegroundColor Cyan
            for ($idx = 0; $idx -lt $previewWriteItems.Count; $idx++) {
                $itemText = (& $formatJpgSample $previewWriteItems[$idx]).TrimStart()
                Write-Host ("  [{0}/{1}] {2}" -f ($idx + 1), $previewWriteItems.Count, $itemText) -ForegroundColor Gray
            }
            Write-Host (T 'PreviewAllEnd') -ForegroundColor Cyan
            Write-Host ""
            continue
        }
        if ($ans -in @('Y', 'y')) { break }
        Write-Host (T 'JpgCancelled') -ForegroundColor Yellow
        exit 0
    }
}

$written      = 0
$failed       = 0
$backupDone   = 0
$pctMap       = @{ 1 = 1; 2 = 25; 3 = 50; 4 = 75; 5 = 99 }
$utf8NoBom    = New-Object System.Text.UTF8Encoding $false
$writeItems   = @($matchedItems | Where-Object { $_.Status -eq 'new' -or $_.Status -eq 'update' })

if ($useSidecar) {
    $newSidecars  = @($writeItems | Where-Object { -not $_.XmpExists })
    $editSidecars = @{}

    foreach ($item in $newSidecars) {
        $star = $item.TargetRating
        $xml = @"
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Lightroom RAW Toolkit">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:xmp="http://ns.adobe.com/xap/1.0/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/"
    xmp:Rating="$star"
    dc:format="image/jpeg"
    photoshop:SidecarForExtension="JPG"/>
 </rdf:RDF>
</x:xmpmeta>
"@
        try {
            [IO.File]::WriteAllText($item.XmpPath, $xml, $utf8NoBom)
            $written++
            $logLines.Add("[OK]   created sidecar: $($item.XmpPath) -> ${star}star")
        } catch {
            Write-Host (T 'JpgWriteFail' @($star, 0, 0, $_.Exception.Message)) -ForegroundColor Red
            $failed++
            $logLines.Add("[FAIL] create sidecar: $($item.XmpPath) -> $($_.Exception.Message)")
        }
    }

    foreach ($item in ($writeItems | Where-Object { $_.XmpExists })) {
        $star = $item.TargetRating
        if (-not $editSidecars.ContainsKey($star)) {
            $editSidecars[$star] = New-Object System.Collections.Generic.List[string]
        }
        $editSidecars[$star].Add($item.XmpPath)
    }

    foreach ($star in ($editSidecars.Keys | Sort-Object)) {
        $files = $editSidecars[$star]
        Write-Host (T 'JpgWritingSidecar' @($star, $files.Count)) -ForegroundColor Cyan
        $chunk = 500
        for ($i = 0; $i -lt $files.Count; $i += $chunk) {
            $n = [Math]::Min($chunk, $files.Count - $i)
            [string[]]$slice = $files.GetRange($i, $n).ToArray()
            $argFile = Join-Path $env:TEMP ("lrt_xmp_w_{0}_{1}_{2}.txt" -f $PID, $star, $i)
            $prevEap = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                [IO.File]::WriteAllLines($argFile, $slice, $utf8NoBom)
                $etArgs = New-Object System.Collections.Generic.List[string]
                $etArgs.Add('-charset'); $etArgs.Add('filename=UTF8')
                $etArgs.Add('-P')
                $etArgs.Add('-overwrite_original_in_place')
                $etArgs.Add("-XMP:Rating=$star")
                $etArgs.Add('-XMP-photoshop:SidecarForExtension=JPG')
                $etArgs.Add('-XMP-dc:Format=image/jpeg')
                $etArgs.Add('-m')
                $etArgs.Add('-@'); $etArgs.Add($argFile)
                [string[]]$argArr = $etArgs.ToArray()
                $result = & $ExifToolPath @argArr 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host (T 'JpgWriteFail' @($star, $i, ($i + $n - 1), ($result -join ' '))) -ForegroundColor Red
                    $failed += $n
                    foreach ($fp in $slice) { $logLines.Add("[FAIL] update sidecar: $fp -> ${star}star") }
                } else {
                    Write-Host (T 'JpgWriteOk' @($n, $star)) -ForegroundColor Green
                    $written += $n
                    foreach ($fp in $slice) { $logLines.Add("[OK]   updated sidecar: $fp -> ${star}star") }
                }
            } finally {
                $ErrorActionPreference = $prevEap
                Remove-Item -LiteralPath $argFile -ErrorAction SilentlyContinue
            }
        }
    }
} else {
    $buckets = @{}
    if (-not $NoBackup.IsPresent -and $writeItems.Count -gt 0) {
        Write-Host (T 'JpgBackingUp' @($writeItems.Count, $effectiveBackupDir)) -ForegroundColor DarkGray
        New-Item -ItemType Directory -Path $effectiveBackupDir -Force | Out-Null
    }

    foreach ($item in $writeItems) {
        if (-not $NoBackup.IsPresent) {
            $full = $item.File.FullName
            $relPath = if ($full.StartsWith($JpgRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
                $full.Substring($JpgRoot.Length + 1)
            } else {
                $item.File.Name
            }
            $dstPath = Join-Path $effectiveBackupDir $relPath
            $dstDir  = [IO.Path]::GetDirectoryName($dstPath)
            try {
                if (-not (Test-Path -LiteralPath $dstDir -PathType Container)) {
                    New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
                }
                [IO.File]::Copy($full, $dstPath, $true)
                [IO.File]::SetLastWriteTimeUtc($dstPath, $item.File.LastWriteTimeUtc)
                $backupDone++
            } catch {
                Write-Host (T 'JpgBackupFail' @($full, $_.Exception.Message)) -ForegroundColor Red
                $failed++
                $logLines.Add("[FAIL] backup: $full -> $($_.Exception.Message)")
                continue
            }
        }

        $star = $item.TargetRating
        if (-not $buckets.ContainsKey($star)) {
            $buckets[$star] = New-Object System.Collections.Generic.List[string]
        }
        $buckets[$star].Add($item.File.FullName)
    }

    if (-not $NoBackup.IsPresent -and $backupDone -gt 0) {
        try {
            $mfObj = [ordered]@{
                CreatedAt = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                JpgRoot   = $JpgRoot
                FileCount = $backupDone
            }
            [IO.File]::WriteAllText((Join-Path $effectiveBackupDir 'manifest.json'), ($mfObj | ConvertTo-Json), $utf8NoBom)
        } catch {}
    }

    foreach ($star in ($buckets.Keys | Sort-Object)) {
        $files = $buckets[$star]
        $pct   = if ($pctMap.ContainsKey($star)) { $pctMap[$star] } else { 99 }
        Write-Host (T 'JpgWritingBatch' @($star, $files.Count)) -ForegroundColor Cyan
        $chunk = 500
        for ($i = 0; $i -lt $files.Count; $i += $chunk) {
            $n = [Math]::Min($chunk, $files.Count - $i)
            [string[]]$slice = $files.GetRange($i, $n).ToArray()
            $argFile = Join-Path $env:TEMP ("lrt_jpg_w_{0}_{1}_{2}.txt" -f $PID, $star, $i)
            $prevEap = $ErrorActionPreference
            try {
                $ErrorActionPreference = 'Continue'
                [IO.File]::WriteAllLines($argFile, $slice, $utf8NoBom)
                $etArgs = New-Object System.Collections.Generic.List[string]
                $etArgs.Add('-charset'); $etArgs.Add('filename=UTF8')
                $etArgs.Add('-P')
                $etArgs.Add('-overwrite_original_in_place')
                $etArgs.Add("-XMP:Rating=$star")
                $etArgs.Add("-EXIF:Rating=$star")
                $etArgs.Add("-EXIF:RatingPercent=$pct")
                $etArgs.Add("-IPTC:StarRating=$star")
                $etArgs.Add('-m')
                $etArgs.Add('-@'); $etArgs.Add($argFile)
                [string[]]$argArr = $etArgs.ToArray()
                $result = & $ExifToolPath @argArr 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Host (T 'JpgWriteFail' @($star, $i, ($i + $n - 1), ($result -join ' '))) -ForegroundColor Red
                    $failed += $n
                    foreach ($fp in $slice) { $logLines.Add("[FAIL] write jpg: $fp -> ${star}star") }
                } else {
                    Write-Host (T 'JpgWriteOk' @($n, $star)) -ForegroundColor Green
                    $written += $n
                    foreach ($fp in $slice) { $logLines.Add("[OK]   write jpg: $fp -> ${star}star") }
                }
            } finally {
                $ErrorActionPreference = $prevEap
                Remove-Item -LiteralPath $argFile -ErrorAction SilentlyContinue
            }
        }
    }
}

try {
    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logPath = Join-Path $logDir ("jpg_restore_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $logLines | Out-File -LiteralPath $logPath -Encoding UTF8
} catch {
    $logPath = $null
}

Write-Host ""
Write-Host (T 'JpgSummaryHeader') -ForegroundColor Cyan
Write-Host (T 'JpgSummaryCounts' @($written, $totalSkipSame, $totalSafeSkip, $noRating, $failed))
Write-Host ""
if ($useSidecar) {
    Write-Host (T 'JpgDoneSidecar') -ForegroundColor DarkGray
} elseif ($NoBackup.IsPresent) {
    Write-Host (T 'JpgDoneNoBackup') -ForegroundColor DarkGray
} elseif ($backupDone -gt 0) {
    Write-Host (T 'JpgDoneBackupPath' @($effectiveBackupDir)) -ForegroundColor DarkGray
}
Write-Host (T 'JpgWriteNext') -ForegroundColor Magenta
if ($logPath) { Write-Host (T 'DoneLogPath' @($logPath)) -ForegroundColor DarkGray }

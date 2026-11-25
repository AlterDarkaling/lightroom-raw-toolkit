<#
.SYNOPSIS
  Automated isolated test suite for lightroom-raw-toolkit.
  All fixtures are generated in $env:TEMP and cleaned up automatically.
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>
param(
    [string]$ExifToolPath
)

$ErrorActionPreference = 'Stop'

$testDir     = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$projectRoot = [IO.Path]::GetDirectoryName($testDir.TrimEnd('\', '/'))
$libPath     = Join-Path $projectRoot 'lib\PhotoMetaCommon.ps1'
$cleanScript    = Join-Path $projectRoot 'scripts\Clean-RawToRecycleBin.ps1'
$restScript     = Join-Path $projectRoot 'scripts\Restore-RatingToJpg.ps1'
$rollbackScript = Join-Path $projectRoot 'scripts\Rollback-JpgBackup.ps1'

. $libPath

$resolvedEt = Resolve-ExifToolPath -ExplicitPath $ExifToolPath -ProjectRoot $projectRoot -ScriptDir $testDir
if (-not (Test-Path -LiteralPath $resolvedEt -PathType Leaf)) {
    throw "exiftool.exe is required to run tests. Pass -ExifToolPath or place it in tools\. Checked: $resolvedEt"
}
$resolvedEt = (Resolve-Path -LiteralPath $resolvedEt).Path

$script:Passed = 0
$script:Failed = 0

function Assert-True([bool]$Condition, [string]$Message) {
    if ($Condition) {
        $script:Passed++
        Write-Host ("[PASS] {0}" -f $Message) -ForegroundColor Green
    } else {
        $script:Failed++
        Write-Host ("[FAIL] {0}" -f $Message) -ForegroundColor Red
    }
}

# Minimal valid 1x1 JPEG bytes
[byte[]]$script:TinyJpg = @(
    0xFF,0xD8,0xFF,0xE0,0x00,0x10,0x4A,0x46,0x49,0x46,0x00,0x01,0x01,0x01,0x00,0x48,
    0x00,0x48,0x00,0x00,0xFF,0xDB,0x00,0x43,0x00,0x03,0x02,0x02,0x03,0x02,0x02,0x03,
    0x03,0x03,0x03,0x04,0x03,0x03,0x04,0x05,0x08,0x05,0x05,0x04,0x04,0x05,0x0A,0x07,
    0x07,0x06,0x08,0x0C,0x0A,0x0C,0x0C,0x0B,0x0A,0x0B,0x0B,0x0D,0x0E,0x12,0x10,0x0D,
    0x0E,0x11,0x0E,0x0B,0x0B,0x10,0x16,0x10,0x11,0x13,0x14,0x15,0x15,0x15,0x0C,0x0F,
    0x17,0x18,0x16,0x14,0x18,0x12,0x14,0x15,0x14,0xFF,0xC0,0x00,0x0B,0x08,0x00,0x01,
    0x00,0x01,0x01,0x01,0x11,0x00,0xFF,0xC4,0x00,0x14,0x00,0x01,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,0xFF,0xC4,0x00,0x14,
    0x10,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0xFF,0xDA,0x00,0x08,0x01,0x01,0x00,0x00,0x3F,0x00,0xD2,0xCF,0x20,0xFF,0xD9
)

function New-TestJpg([string]$Path, [int]$Rating = 0) {
    $dir = [IO.Path]::GetDirectoryName($Path)
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllBytes($Path, $script:TinyJpg)
    if ($Rating -ge 1) {
        $prev = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $resolvedEt -q -overwrite_original "-XMP:Rating=$Rating" $Path 2>$null
        } finally {
            $ErrorActionPreference = $prev
        }
    }
}

function New-TestXmp([string]$Path, [int]$Rating, [string]$ForExt, [string]$Mime, [string]$RawFile) {
    $dir = [IO.Path]::GetDirectoryName($Path)
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $xml = @"
<x:xmpmeta xmlns:x="adobe:ns:meta/">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:xmp="http://ns.adobe.com/xap/1.0/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/"
    xmp:Rating="$Rating"
    dc:format="$Mime"
    photoshop:SidecarForExtension="$ForExt"
    crs:RawFileName="$RawFile"
    xmlns:crs="http://ns.adobe.com/camera-raw-settings/1.0/"/>
 </rdf:RDF>
</x:xmpmeta>
"@
    [IO.File]::WriteAllText($Path, $xml, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "=== 1. Encoding, Syntax & i18n Completeness ===" -ForegroundColor Cyan
$ps1Files = @(
    $libPath,
    $cleanScript,
    $restScript,
    $rollbackScript,
    (Join-Path $projectRoot 'scripts\Start-Toolkit.ps1'),
    (Join-Path $testDir 'Run-Tests.ps1')
)
foreach ($f in $ps1Files) {
    $b = [IO.File]::ReadAllBytes($f)
    $hasBom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    $tokens = $null; $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errs)
    Assert-True ($hasBom -and $errs.Count -eq 0) ("PS1 UTF8-BOM & AST clean: $(Split-Path -Leaf $f)")
}
$rootBat = Join-Path $projectRoot 'Start-Toolkit.bat'
$batBytes = [IO.File]::ReadAllBytes($rootBat)
$batBom = ($batBytes.Length -ge 3 -and $batBytes[0] -eq 0xEF -and $batBytes[1] -eq 0xBB -and $batBytes[2] -eq 0xBF)
Assert-True ((Test-Path -LiteralPath $rootBat -PathType Leaf) -and (-not $batBom)) 'Root Start-Toolkit.bat exists and has NO BOM'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'launchers'))) 'Old launchers/ folder removed'

$enKeys = @($script:LrtMessages['en'].Keys | Sort-Object)
$zhKeys = @($script:LrtMessages['zh'].Keys | Sort-Object)
$missingInZh = @($enKeys | Where-Object { $zhKeys -notcontains $_ })
$missingInEn = @($zhKeys | Where-Object { $enKeys -notcontains $_ })
Assert-True ($missingInZh.Count -eq 0 -and $missingInEn.Count -eq 0) "i18n en/zh key sets match ($($enKeys.Count) keys)"

Write-Host "`n=== 2. Unit Tests ===" -ForegroundColor Cyan
Assert-True ((Merge-Rating $null 0) -eq 0)   'Merge-Rating(null, 0) = 0'
Assert-True ((Merge-Rating 0 -1) -eq -1)    'Merge-Rating(0, -1) = -1 (unreadable beats 0)'
Assert-True ((Merge-Rating -1 0) -eq -1)    'Merge-Rating(-1, 0) = -1 (0 never clears -1)'
Assert-True ((Merge-Rating -1 2) -eq 2)     'Merge-Rating(-1, 2) = 2 (rated beats -1)'
Assert-True ((Merge-Rating 1 -1) -eq 1)     'Merge-Rating(1, -1) = 1 (rated beats -1)'

Assert-True ((Try-ParseDatePrefix '2026-10-18') -eq [datetime]'2026-10-18')      'Try-ParseDatePrefix exact yyyy-MM-dd'
Assert-True ((Try-ParseDatePrefix '2026-10-18_Trip') -eq [datetime]'2026-10-18') 'Try-ParseDatePrefix yyyy-MM-dd_Trip'
Assert-True ($null -eq (Try-ParseDatePrefix '2026-02-30'))                        'Try-ParseDatePrefix rejects Feb 30'
Assert-True ($null -eq (Try-ParseDatePrefix 'random_folder'))                     'Try-ParseDatePrefix ignores non-date'

$tmpBase = Join-Path $env:TEMP ("lrt_test_{0}" -f $PID)
if (Test-Path -LiteralPath $tmpBase) { Remove-Item -LiteralPath $tmpBase -Recurse -Force }
New-Item -ItemType Directory -Path $tmpBase -Force | Out-Null

$logDir   = Join-Path $projectRoot 'logs'
$hadLogs  = Test-Path -LiteralPath $logDir
$preLogs  = if ($hadLogs) { @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' | ForEach-Object { $_.FullName }) } else { @() }

$backupRoot    = Join-Path $projectRoot 'backups'
$hadBackupRoot = Test-Path -LiteralPath $backupRoot
$preBackups    = if ($hadBackupRoot) { @(Get-ChildItem -LiteralPath $backupRoot | ForEach-Object { $_.FullName }) } else { @() }

try {
    # Unit: Test-SidecarBelongsToRaw
    $uDir = Join-Path $tmpBase 'unit'
    New-Item -ItemType Directory -Path $uDir -Force | Out-Null
    $hifXmp = Join-Path $uDir 'A.xmp'
    New-TestXmp $hifXmp 1 'HIF' 'image/heic' 'A.HIF'
    Assert-True (-not (Test-SidecarBelongsToRaw $hifXmp (Join-Path $uDir 'A.ARW') @{ 'a.hif' = 1 })) 'Test-SidecarBelongsToRaw rejects HIF XMP for ARW'
    $cr3Xmp = Join-Path $uDir 'B.xmp'
    New-TestXmp $cr3Xmp 0 'CR3' 'image/x-canon-cr3' 'B.CR3'
    Assert-True (Test-SidecarBelongsToRaw $cr3Xmp (Join-Path $uDir 'B.CR3') @{ 'b.jpg' = 1 }) 'Test-SidecarBelongsToRaw accepts CR3 XMP for CR3'
    Assert-True ($null -eq (Test-SidecarBelongsToRaw (Join-Path $uDir 'missing.xmp') (Join-Path $uDir 'missing.ARW') @{})) 'Test-SidecarBelongsToRaw returns null on unreadable file'

    # Unit: Resolve-CatalogPath newest non-backup wins
    $lrParent = Join-Path $tmpBase 'cat_test'
    $lrDir    = Join-Path $lrParent 'Lightroom'
    $photoDir = Join-Path $lrParent '2026'
    New-Item -ItemType Directory -Path $lrDir, $photoDir -Force | Out-Null
    $oldCat = Join-Path $lrDir 'Old.lrcat'
    $newCat = Join-Path $lrDir 'Lightroom Catalog-v13.lrcat'
    $bakCat = Join-Path $lrDir 'Lightroom Catalog Backup.lrcat'
    [IO.File]::WriteAllText($oldCat, '')
    [IO.File]::WriteAllText($newCat, '')
    [IO.File]::WriteAllText($bakCat, '')
    (Get-Item $oldCat).LastWriteTime = (Get-Date).AddDays(-2)
    (Get-Item $newCat).LastWriteTime = (Get-Date).AddDays(-1)
    (Get-Item $bakCat).LastWriteTime = (Get-Date)
    Assert-True ((Resolve-CatalogPath $null $photoDir) -eq $newCat) 'Resolve-CatalogPath picks newest non-backup .lrcat'

    # Unit: config.local.json round-trip
    $cfgDir = Join-Path $tmpBase 'cfg_test'
    New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    Save-ToolkitLocalConfig -ProjectRoot $cfgDir -LastRoot $photoDir -Lang 'zh'
    $loadedCfg = Get-ToolkitLocalConfig -ProjectRoot $cfgDir
    Assert-True ($null -ne $loadedCfg -and $loadedCfg.LastRoot -eq $photoDir -and $loadedCfg.Lang -eq 'zh') 'Save/Get-ToolkitLocalConfig round-trips LastRoot and Lang'

    Write-Host "`n=== 3. End-to-End Cleanup LIVE Test (Multi-RAW + ACR + JPG-XMP + LR) ===" -ForegroundColor Cyan
    $e2eRoot = Join-Path $tmpBase 'e2e'
    $e2ePhotos = Join-Path $e2eRoot '2026'
    $e2eLr     = Join-Path $e2eRoot 'Lightroom'
    New-Item -ItemType Directory -Path $e2ePhotos, $e2eLr -Force | Out-Null

    # Use valid tiny JPEG content as dummy RAWs too (ExifTool parses FileType=JPEG cleanly and reads XMP/EXIF!)
    # Wait: ExifTool checks actual file bytes for FileType; TinyJpg is valid for any ext with ExifTool!
    # Case 1: 2026-10-18_Trip -> unrated .ARW + .CR3 + .acr + nested subfolder drone\D01.DNG + .JPG
    $d1 = Join-Path $e2ePhotos '2026-10-18_Trip'
    $d1Sub = Join-Path $d1 'drone'
    New-TestJpg (Join-Path $d1 'S01.ARW') 0
    New-TestJpg (Join-Path $d1 'S01.JPG') 0
    [IO.File]::WriteAllText((Join-Path $d1 'S01.acr'), 'acr')
    New-TestJpg (Join-Path $d1 'C01.CR3') 0
    New-TestJpg (Join-Path $d1 'C01.JPG') 0
    New-TestJpg (Join-Path $d1Sub 'D01.DNG') 0
    New-TestJpg (Join-Path $d1Sub 'D01.JPG') 0

    # Case 2: 2026-10-19 -> unrated .ARW + ARW-owned .xmp (0*) + .JPG -> ARW & .xmp deleted, JPG kept
    $d2 = Join-Path $e2ePhotos '2026-10-19'
    New-TestJpg (Join-Path $d2 'S02.ARW') 0
    New-TestJpg (Join-Path $d2 'S02.JPG') 0
    New-TestXmp (Join-Path $d2 'S02.xmp') 0 'ARW' 'image/x-sony-arw' 'S02.ARW'

    # Case 3: 2026-10-20 -> XMP-rated .NEF -> kept
    $d3 = Join-Path $e2ePhotos '2026-10-20'
    New-TestJpg (Join-Path $d3 'N01.NEF') 0
    New-TestJpg (Join-Path $d3 'N01.JPG') 0
    New-TestXmp (Join-Path $d3 'N01.xmp') 4 'NEF' 'image/x-nikon-nef' 'N01.NEF'

    # Case 4: 2026-10-21 -> JPG-rated (2*) keeps .ARW
    $d4 = Join-Path $e2ePhotos '2026-10-21'
    New-TestJpg (Join-Path $d4 'S03.ARW') 0
    New-TestJpg (Join-Path $d4 'S03.JPG') 2

    # Case 5: 2026-10-22 -> JPG-owned XMP (3*) keeps .ARW AND keeps JPG XMP
    $d5 = Join-Path $e2ePhotos '2026-10-22'
    New-TestJpg (Join-Path $d5 'S04.ARW') 0
    New-TestJpg (Join-Path $d5 'S04.JPG') 0
    New-TestXmp (Join-Path $d5 'S04.xmp') 3 'JPG' 'image/jpeg' 'S04.JPG'

    # Case 6: 2026-10-23 -> HIF + HIF-owned XMP + unrated ARW -> only ARW deleted; HIF & XMP kept
    $d6 = Join-Path $e2ePhotos '2026-10-23'
    New-TestJpg (Join-Path $d6 'H01.ARW') 0
    New-TestJpg (Join-Path $d6 'H01.HIF') 0
    New-TestXmp (Join-Path $d6 'H01.xmp') 0 'HIF' 'image/heic' 'H01.HIF'

    # Case 7: 2026-10-24 -> RAW-only (no JPG) -> kept by default
    $d7 = Join-Path $e2ePhotos '2026-10-24'
    New-TestJpg (Join-Path $d7 'RAWONLY.ARW') 0

    # Case 8: 2026-10-25 -> LR catalog rated (rating=2) and picked (pick=1) -> both kept; plus .lrcat.lock warning
    $d8 = Join-Path $e2ePhotos '2026-10-25'
    New-TestJpg (Join-Path $d8 'LR_STAR.ARW') 0
    New-TestJpg (Join-Path $d8 'LR_STAR.JPG') 0
    New-TestJpg (Join-Path $d8 'LR_PICK.ARW') 0
    New-TestJpg (Join-Path $d8 'LR_PICK.JPG') 0

    # Case 9: 2026-11-01 -> cutoff day -> kept
    $d9 = Join-Path $e2ePhotos '2026-11-01'
    New-TestJpg (Join-Path $d9 'CUTOFF.ARW') 0
    New-TestJpg (Join-Path $d9 'CUTOFF.JPG') 0

    # Build SQLite catalog
    $e2eCat = Join-Path $e2eLr 'Lightroom Catalog-v14.lrcat'
    $pyExe = Resolve-PythonCliPath
    $pyBuild = Join-Path $tmpBase 'mkcat.py'
    $mkCode = @'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
c = con.cursor()
c.execute('CREATE TABLE AgLibraryRootFolder (id_local INTEGER PRIMARY KEY, absolutePath TEXT, name TEXT)')
c.execute('CREATE TABLE AgLibraryFolder (id_local INTEGER PRIMARY KEY, rootFolder INTEGER, pathFromRoot TEXT)')
c.execute('CREATE TABLE AgLibraryFile (id_local INTEGER PRIMARY KEY, folder INTEGER, baseName TEXT, extension TEXT)')
c.execute('CREATE TABLE Adobe_images (id_local INTEGER PRIMARY KEY, rootFile INTEGER, rating REAL, pick REAL)')
c.execute("INSERT INTO AgLibraryRootFolder VALUES (1, ?, '2026')", (sys.argv[2],))
c.execute("INSERT INTO AgLibraryFolder VALUES (1, 1, '2026-10-25/')")
c.execute("INSERT INTO AgLibraryFolder VALUES (2, 1, '2026-01-01/')")
c.execute("INSERT INTO AgLibraryFile VALUES (1, 1, 'LR_STAR', 'ARW')")
c.execute("INSERT INTO AgLibraryFile VALUES (2, 1, 'LR_PICK', 'ARW')")
c.execute("INSERT INTO AgLibraryFile VALUES (3, 2, 'IMG_0001', 'ARW')")
c.execute("INSERT INTO AgLibraryFile VALUES (4, 2, 'IMG_0002', 'ARW')")
c.execute("INSERT INTO Adobe_images VALUES (1, 1, 2.0, 0.0)")
c.execute("INSERT INTO Adobe_images VALUES (2, 2, 0.0, 1.0)")
c.execute("INSERT INTO Adobe_images VALUES (3, 3, 3.0, 0.0)")
c.execute("INSERT INTO Adobe_images VALUES (4, 4, 4.0, 0.0)")
con.commit()
con.close()
'@
    [IO.File]::WriteAllText($pyBuild, $mkCode, (New-Object System.Text.UTF8Encoding $false))
    $absE2e = $e2ePhotos.Replace('\', '/') + '/'
    & $pyExe $pyBuild $e2eCat $absE2e
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $e2eCat -PathType Leaf)) {
        throw "Failed to create test Lightroom catalog fixture: $e2eCat (exit=$LASTEXITCODE)"
    }
    [IO.File]::WriteAllText(($e2eCat + '.lock'), '')

    # Run dry-run in Chinese first to verify -Lang zh and check no unformatted {0} tokens
    $zhOut = (& $cleanScript -RootPath $e2ePhotos -ExifToolPath $resolvedEt -BeforeDate '2026-11-01' -Lang zh -DryRun 6>&1 | Out-String)
    Write-Host $zhOut
    Assert-True ($LASTEXITCODE -eq 0 -and ($zhOut -match '预览') -and ($zhOut -match '待删格式分布') -and ($zhOut -match '待处理文件预览') -and ($zhOut -match 'S01\.ARW') -and ($zhOut -notmatch '\{0\}')) 'Clean-RawToRecycleBin -Lang zh -DryRun shows format stats & top-10 file preview cleanly'

    # Run LIVE cleanup with relative path and -Lang en
    Push-Location $e2eRoot
    try {
        & $cleanScript -RootPath '.\2026' -ExifToolPath $resolvedEt -BeforeDate '2026-11-01' -Lang en -NoConfirm
    } finally {
        Pop-Location
    }
    Assert-True ($LASTEXITCODE -eq 0) 'Clean-RawToRecycleBin LIVE exited 0'

    foreach ($delPath in @(
        (Join-Path $d1 'S01.ARW'),
        (Join-Path $d1 'S01.acr'),
        (Join-Path $d1 'C01.CR3'),
        (Join-Path $d1Sub 'D01.DNG'),
        (Join-Path $d2 'S02.ARW'),
        (Join-Path $d2 'S02.xmp'),
        (Join-Path $d6 'H01.ARW')
    )) {
        Assert-True (-not (Test-Path -LiteralPath $delPath)) ("Deleted: $(Split-Path -Leaf $delPath)")
    }
    foreach ($keepPath in @(
        (Join-Path $d1 'S01.JPG'),
        (Join-Path $d1 'C01.JPG'),
        (Join-Path $d1Sub 'D01.JPG'),
        (Join-Path $d2 'S02.JPG'),
        (Join-Path $d3 'N01.NEF'),
        (Join-Path $d3 'N01.xmp'),
        (Join-Path $d4 'S03.ARW'),
        (Join-Path $d5 'S04.ARW'),
        (Join-Path $d5 'S04.xmp'),
        (Join-Path $d6 'H01.HIF'),
        (Join-Path $d6 'H01.xmp'),
        (Join-Path $d7 'RAWONLY.ARW'),
        (Join-Path $d8 'LR_STAR.ARW'),
        (Join-Path $d8 'LR_PICK.ARW'),
        (Join-Path $d9 'CUTOFF.ARW')
    )) {
        Assert-True (Test-Path -LiteralPath $keepPath) ("Kept: $(Split-Path -Leaf $keepPath)")
    }

    # Test non-date folder CLI hint & -UseFileDate flat mode
    $flatDir = Join-Path $tmpBase 'flat'
    New-TestJpg (Join-Path $flatDir 'OLD.ARW') 0
    New-TestJpg (Join-Path $flatDir 'OLD.JPG') 0
    New-TestJpg (Join-Path $flatDir 'NEW.ARW') 0
    New-TestJpg (Join-Path $flatDir 'NEW.JPG') 0
    (Get-Item (Join-Path $flatDir 'OLD.ARW')).LastWriteTime = [datetime]'2026-01-10'
    (Get-Item (Join-Path $flatDir 'NEW.ARW')).LastWriteTime = [datetime]'2026-11-10'
    $nonDateHintOut = (& $cleanScript -RootPath $flatDir -ExifToolPath $resolvedEt -BeforeDate '2026-06-01' -NoCatalog -Lang zh -DryRun 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($nonDateHintOut -match '-UseFileDate') -and ($nonDateHintOut -notmatch '\{0\}')) 'Clean-RawToRecycleBin emits -UseFileDate tip on non-date folder'
    & $cleanScript -RootPath $flatDir -ExifToolPath $resolvedEt -UseFileDate -BeforeDate '2026-06-01' -NoCatalog -Lang en -NoConfirm
    Assert-True ((-not (Test-Path -LiteralPath (Join-Path $flatDir 'OLD.ARW'))) -and (Test-Path -LiteralPath (Join-Path $flatDir 'NEW.ARW'))) '-UseFileDate deletes old RAW and keeps new RAW'

    Write-Host "`n=== 4. End-to-End Restore-RatingToJpg LIVE Test (Incremental Skip + -P + Centralized Backup + SidecarOnly) ===" -ForegroundColor Cyan
    $jpg1 = Join-Path $e2ePhotos '2026-01-01\IMG_0001.JPG'
    $jpgAlready = Join-Path $e2ePhotos '2026-01-01\IMG_0002.JPG'
    $jpg2 = Join-Path $e2ePhotos '2026-01-02\IMG_0001.JPG'
    New-TestJpg $jpg1 0
    New-TestJpg $jpgAlready 4
    New-TestJpg $jpg2 0
    $fixedTs1 = [datetime]'2026-01-01 09:30:00'
    $fixedTs2 = [datetime]'2026-01-01 10:00:00'
    (Get-Item -LiteralPath $jpg1).LastWriteTime = $fixedTs1
    (Get-Item -LiteralPath $jpgAlready).LastWriteTime = $fixedTs2
    $preHash1 = (Get-FileHash -LiteralPath $jpg1 -Algorithm SHA256).Hash
    $preHashAlready = (Get-FileHash -LiteralPath $jpgAlready -Algorithm SHA256).Hash
    $preLwt1 = (Get-Item -LiteralPath $jpg1).LastWriteTime
    $preLwtAlready = (Get-Item -LiteralPath $jpgAlready).LastWriteTime
    Remove-Item -LiteralPath ($e2eCat + '.lock') -ErrorAction SilentlyContinue

    # 4a. Dry-run preview in Chinese (no files touched, no unformatted placeholders)
    $jpgDryZh = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -DryRun -Lang zh 6>&1 | Out-String)
    Write-Host $jpgDryZh
    Assert-True ($LASTEXITCODE -eq 0 -and ($jpgDryZh -match '预览') -and ($jpgDryZh -match '待处理文件预览') -and ($jpgDryZh -match 'IMG_0001\.JPG') -and ($jpgDryZh -match '网盘提示') -and ($jpgDryZh -notmatch '\{0\}')) 'Restore-RatingToJpg -DryRun -Lang zh shows top-10 preview & formatted placeholders'
    Assert-True (((Get-FileHash -LiteralPath $jpg1 -Algorithm SHA256).Hash -eq $preHash1)) 'DryRun did not modify matched unrated JPG'

    # 4b. Live run with -NoConfirm (incremental skip + -P + centralized backup)
    $jpgLiveOut = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -Lang en -NoConfirm 6>&1 | Out-String)
    Write-Host $jpgLiveOut
    Assert-True ($LASTEXITCODE -eq 0 -and ($jpgLiveOut -notmatch '\{0\}')) 'Restore-RatingToJpg -NoConfirm exited 0'
    $inPhotoOrigs = @(Get-ChildItem -LiteralPath $e2ePhotos -Recurse -File -Filter '*_original')
    Assert-True ($inPhotoOrigs.Count -eq 0) 'Zero .jpg_original clutter left inside photo folder'
    $newBackups = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Where-Object { $preBackups -notcontains $_.FullName })
    Assert-True ($newBackups.Count -eq 1 -and (Test-Path -LiteralPath (Join-Path $newBackups[0].FullName '2026-01-01\IMG_0001.JPG') -PathType Leaf)) 'Centralized backup created for modified JPG only'
    Assert-True ($newBackups.Count -eq 1 -and (-not (Test-Path -LiteralPath (Join-Path $newBackups[0].FullName '2026-01-01\IMG_0002.JPG')))) 'Already-same-rating JPG was not backed up or touched'
    Assert-True (((Get-FileHash -LiteralPath $jpgAlready -Algorithm SHA256).Hash -eq $preHashAlready) -and ((Get-Item -LiteralPath $jpgAlready).LastWriteTime -eq $preLwtAlready)) 'Already-same-rating JPG skipped (hash & mtime unchanged)'
    Assert-True ([Math]::Abs(((Get-Item -LiteralPath $jpg1).LastWriteTime - $preLwt1).TotalSeconds) -le 2) 'ExifTool -P preserved original LastWriteTime on modified JPG'

    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $metaJson = (& $resolvedEt -json -XMP:Rating -EXIF:Rating -EXIF:RatingPercent $jpg1 $jpg2 2>$null) | Out-String | ConvertFrom-Json
    } finally {
        $ErrorActionPreference = $prev
    }
    Assert-True ($metaJson[0].Rating -eq 3 -or $metaJson[0].RatingPercent -eq 50) 'Matched JPG received 3-star / 50% rating'
    Assert-True ($null -eq $metaJson[1].Rating) 'Unmatched same-name JPG remains unrated'

    # 4c. Re-run DryRun: all matched JPGs should now be skipped (0 to write)
    $jpgReDry = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -DryRun -Lang zh 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($jpgReDry -match '无需修改任何文件')) 'Second run skips all already-rated JPGs'

    # 4c-2. Verify manifest.json + jpg_restore_*.log + Rollback-JpgBackup + SubFolder/RecentDays scope
    $mfPath = Join-Path $newBackups[0].FullName 'manifest.json'
    Assert-True (Test-Path -LiteralPath $mfPath -PathType Leaf) 'Backup folder contains manifest.json'
    $mfObj = ([IO.File]::ReadAllText($mfPath, [System.Text.Encoding]::UTF8)) | ConvertFrom-Json
    Assert-True ($mfObj.JpgRoot -eq $e2ePhotos.TrimEnd('\', '/')) 'manifest.json records exact JpgRoot'
    $newJpgLogs = @(Get-ChildItem -LiteralPath $logDir -Filter 'jpg_restore_*.log' | Where-Object { $preLogs -notcontains $_.FullName })
    Assert-True ($newJpgLogs.Count -ge 1) 'Restore-RatingToJpg wrote operation log in logs\'

    $rbDryZh = (& $rollbackScript -BackupDir $newBackups[0].FullName -DryRun -Lang zh 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($rbDryZh -match '待处理文件预览') -and ($rbDryZh -match 'IMG_0001\.JPG') -and ($rbDryZh -notmatch '\{0\}')) 'Rollback-JpgBackup -DryRun -Lang zh shows file preview cleanly'

    $rbOut = (& $rollbackScript -BackupDir $newBackups[0].FullName -NoConfirm -Lang en 6>&1 | Out-String)
    Write-Host $rbOut
    Assert-True ($LASTEXITCODE -eq 0 -and ($rbOut -notmatch '\{0\}')) 'Rollback-JpgBackup exited 0 cleanly'
    Assert-True (((Get-FileHash -LiteralPath $jpg1 -Algorithm SHA256).Hash -eq $preHash1)) 'Rollback-JpgBackup restored exact original SHA256 bytes'
    Assert-True ([Math]::Abs(((Get-Item -LiteralPath $jpg1).LastWriteTime - $preLwt1).TotalSeconds) -le 2) 'Rollback-JpgBackup restored original LastWriteTime'

    $subDryOut = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -SubFolder '2026-01-01' -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($subDryOut -match 'subfolder 2026-01-01') -and ($subDryOut -match 'To write: 1')) 'Restore-RatingToJpg -SubFolder scopes accurately'
    $recDryOut = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -RecentDays 7 -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($recDryOut -match 'No JPG files found')) 'Restore-RatingToJpg -RecentDays filters out old folders cleanly'

    # 4d. Sidecar-only mode test (JPG bytes untouched + RAW XMP ownership conflict safe-skipped)
    $scParent = Join-Path $tmpBase 'sidecar_test'
    $scPhotos = Join-Path $scParent 'Photos'
    $scLr     = Join-Path $scParent 'Lightroom'
    $scSub    = Join-Path $scPhotos '2026-01-03'
    New-Item -ItemType Directory -Path $scSub, $scLr -Force | Out-Null
    $scOkJpg  = Join-Path $scSub 'SC_OK.JPG'
    $scConJpg = Join-Path $scSub 'SC_RAWXMP.JPG'
    $scConXmp = Join-Path $scSub 'SC_RAWXMP.xmp'
    New-TestJpg $scOkJpg 0
    New-TestJpg $scConJpg 0
    New-TestXmp $scConXmp 1 'ARW' 'image/x-sony-arw' 'SC_RAWXMP.ARW'
    $scOkHash = (Get-FileHash -LiteralPath $scOkJpg -Algorithm SHA256).Hash
    $scCat = Join-Path $scLr 'SidecarCat.lrcat'
    $pySc = Join-Path $tmpBase 'mkcat_sc.py'
    $mkScCode = @'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
c = con.cursor()
c.execute('CREATE TABLE AgLibraryRootFolder (id_local INTEGER PRIMARY KEY, absolutePath TEXT, name TEXT)')
c.execute('CREATE TABLE AgLibraryFolder (id_local INTEGER PRIMARY KEY, rootFolder INTEGER, pathFromRoot TEXT)')
c.execute('CREATE TABLE AgLibraryFile (id_local INTEGER PRIMARY KEY, folder INTEGER, baseName TEXT, extension TEXT)')
c.execute('CREATE TABLE Adobe_images (id_local INTEGER PRIMARY KEY, rootFile INTEGER, rating REAL, pick REAL)')
c.execute("INSERT INTO AgLibraryRootFolder VALUES (1, ?, 'Photos')", (sys.argv[2],))
c.execute("INSERT INTO AgLibraryFolder VALUES (1, 1, '2026-01-03/')")
c.execute("INSERT INTO AgLibraryFile VALUES (1, 1, 'SC_OK', 'ARW')")
c.execute("INSERT INTO AgLibraryFile VALUES (2, 1, 'SC_RAWXMP', 'ARW')")
c.execute("INSERT INTO Adobe_images VALUES (1, 1, 3.0, 0.0)")
c.execute("INSERT INTO Adobe_images VALUES (2, 2, 5.0, 0.0)")
con.commit()
con.close()
'@
    [IO.File]::WriteAllText($pySc, $mkScCode, (New-Object System.Text.UTF8Encoding $false))
    $absSc = $scPhotos.Replace('\', '/') + '/'
    & $pyExe $pySc $scCat $absSc
    if ($LASTEXITCODE -ne 0) { throw "Failed to create sidecar test catalog: exit=$LASTEXITCODE" }

    $scOut = (& $restScript -JpgRoot $scPhotos -CatalogPath $scCat -ExifToolPath $resolvedEt -SidecarOnly -NoConfirm -Lang en 6>&1 | Out-String)
    Write-Host $scOut
    $scOkXmpPath = Join-Path $scSub 'SC_OK.xmp'
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $scOkXmpPath -PathType Leaf)) 'SidecarOnly created SC_OK.xmp'
    $scOkXmpText = [IO.File]::ReadAllText($scOkXmpPath)
    Assert-True (($scOkXmpText -match 'xmp:Rating="3"') -and ($scOkXmpText -match 'SidecarForExtension="JPG"')) 'Created XMP has Rating=3 and SidecarForExtension=JPG'
    Assert-True (((Get-FileHash -LiteralPath $scOkJpg -Algorithm SHA256).Hash -eq $scOkHash)) 'SidecarOnly left JPG bytes 100% untouched'
    $scConXmpText = [IO.File]::ReadAllText($scConXmp)
    Assert-True (($scConXmpText -match 'xmp:Rating="1"') -and ($scConXmpText -match 'SidecarForExtension="ARW"')) 'SidecarOnly refused to clobber RAW-owned XMP'
    $scReDry = (& $restScript -JpgRoot $scPhotos -CatalogPath $scCat -ExifToolPath $resolvedEt -SidecarOnly -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($scReDry -match 'Nothing to do')) 'SidecarOnly second run skips already-matching sidecar'

    Write-Host "`n=== 5. Unified Menu Smoke Test (-Lang zh & -Lang en & live L toggle) ===" -ForegroundColor Cyan
    $menuScript = Join-Path $projectRoot 'scripts\Start-Toolkit.ps1'
    foreach ($lg in @('zh', 'en')) {
        $mOut = (& $menuScript -RootPath $e2ePhotos -ExifToolPath $resolvedEt -CatalogPath $e2eCat -Lang $lg -NoConfig -AutoChoices @('L', '0') 6>&1 | Out-String)
        Write-Host $mOut
        Assert-True (($mOut -notmatch '\{0\}') -and ($mOut -match 'ExifTool') -and ($mOut -match 'Rollback') -and ($mOut -match 'Lightroom RAW 工具箱') -and ($mOut -match 'Lightroom RAW Toolkit')) ("Start-Toolkit.ps1 -Lang $lg shows env checks, toggles lang, and exits cleanly")
    }
} finally {
    if (Test-Path -LiteralPath $tmpBase) {
        Remove-Item -LiteralPath $tmpBase -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $logDir) {
        $afterLogs = @(Get-ChildItem -LiteralPath $logDir -Filter '*.log' | ForEach-Object { $_.FullName })
        foreach ($nl in ($afterLogs | Where-Object { $preLogs -notcontains $_ })) {
            Remove-Item -LiteralPath $nl -Force -ErrorAction SilentlyContinue
        }
        if (-not $hadLogs -and @(Get-ChildItem -LiteralPath $logDir).Count -eq 0) {
            Remove-Item -LiteralPath $logDir -Force -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path -LiteralPath $backupRoot) {
        $afterBackups = @(Get-ChildItem -LiteralPath $backupRoot | ForEach-Object { $_.FullName })
        foreach ($nb in ($afterBackups | Where-Object { $preBackups -notcontains $_ })) {
            Remove-Item -LiteralPath $nb -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (-not $hadBackupRoot -and @(Get-ChildItem -LiteralPath $backupRoot).Count -eq 0) {
            Remove-Item -LiteralPath $backupRoot -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host ("Test summary: {0} passed, {1} failed" -f $script:Passed, $script:Failed) -ForegroundColor $(if ($script:Failed -eq 0) { 'Green' } else { 'Red' })
if ($script:Failed -gt 0) { exit 1 }

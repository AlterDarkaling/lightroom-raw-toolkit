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
$cleanScript     = Join-Path $projectRoot 'scripts\Clean-RawToRecycleBin.ps1'
$restScript      = Join-Path $projectRoot 'scripts\Restore-RatingToJpg.ps1'
$rollbackScript  = Join-Path $projectRoot 'scripts\Rollback-JpgBackup.ps1'
$installEtScript = Join-Path $projectRoot 'scripts\Install-ExifTool.ps1'

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
    $installEtScript,
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

    # Unit: Install-ExifTool.ps1 offline ZIP extraction & rename
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $etSrcParent = Join-Path $tmpBase 'et_zip_src'
    $etInnerDir  = Join-Path $etSrcParent 'exiftool-13.99_64'
    $etFilesDir  = Join-Path $etInnerDir 'exiftool_files'
    New-Item -ItemType Directory -Path $etFilesDir -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $etInnerDir 'exiftool(-k).exe'), 'dummy-exe')
    [IO.File]::WriteAllText((Join-Path $etFilesDir 'dummy.txt'), 'dummy-lib')
    $testEtZip = Join-Path $tmpBase 'test_exiftool.zip'
    [System.IO.Compression.ZipFile]::CreateFromDirectory($etSrcParent, $testEtZip)
    $etTarget = Join-Path $tmpBase 'et_target'
    $instOut = (& $installEtScript -ZipPath $testEtZip -TargetDir $etTarget -SkipVerify -Lang zh 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath (Join-Path $etTarget 'exiftool.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $etTarget 'exiftool_files\dummy.txt') -PathType Leaf) -and ($instOut -notmatch '\{0\}')) 'Install-ExifTool extracts, renames exiftool(-k).exe, and copies exiftool_files'

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
    $zhOut = (& $cleanScript -RootPath $e2ePhotos -ExifToolPath $resolvedEt -BeforeDate '2026-11-01' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -Lang zh -DryRun 6>&1 | Out-String)
    Write-Host $zhOut
    Assert-True ($LASTEXITCODE -eq 0 -and ($zhOut -match '预览') -and ($zhOut -match '待删格式分布') -and ($zhOut -match '待处理文件预览') -and ($zhOut -match 'S01\.ARW') -and ($zhOut -notmatch '\{0\}')) 'Clean-RawToRecycleBin -Lang zh -DryRun shows format stats & top-10 file preview cleanly'

    # Run LIVE cleanup with relative path and -Lang en
    Push-Location $e2eRoot
    try {
        & $cleanScript -RootPath '.\2026' -ExifToolPath $resolvedEt -BeforeDate '2026-11-01' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -Lang en -NoConfirm
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
    $jpgDryZh = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -DryRun -Lang zh 6>&1 | Out-String)
    Write-Host $jpgDryZh
    Assert-True ($LASTEXITCODE -eq 0 -and ($jpgDryZh -match '预览') -and ($jpgDryZh -match '待处理文件预览') -and ($jpgDryZh -match 'IMG_0001\.JPG') -and ($jpgDryZh -match '网盘提示') -and ($jpgDryZh -notmatch '\{0\}')) 'Restore-RatingToJpg -DryRun -Lang zh shows top-10 preview & formatted placeholders'
    Assert-True (((Get-FileHash -LiteralPath $jpg1 -Algorithm SHA256).Hash -eq $preHash1)) 'DryRun did not modify matched unrated JPG'

    # 4b. Live run with -NoConfirm (incremental skip + -P + centralized backup)
    $jpgLiveOut = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -Lang en -NoConfirm 6>&1 | Out-String)
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
    $jpgReDry = (& $restScript -JpgRoot $e2ePhotos -CatalogPath $e2eCat -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -DryRun -Lang zh 6>&1 | Out-String)
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

    $scOut = (& $restScript -JpgRoot $scPhotos -CatalogPath $scCat -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -SidecarOnly -NoConfirm -Lang en 6>&1 | Out-String)
    Write-Host $scOut
    $scOkXmpPath = Join-Path $scSub 'SC_OK.xmp'
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $scOkXmpPath -PathType Leaf)) 'SidecarOnly created SC_OK.xmp'
    $scOkXmpText = [IO.File]::ReadAllText($scOkXmpPath)
    Assert-True (($scOkXmpText -match 'xmp:Rating="3"') -and ($scOkXmpText -match 'SidecarForExtension="JPG"')) 'Created XMP has Rating=3 and SidecarForExtension=JPG'
    Assert-True (((Get-FileHash -LiteralPath $scOkJpg -Algorithm SHA256).Hash -eq $scOkHash)) 'SidecarOnly left JPG bytes 100% untouched'
    $scConXmpText = [IO.File]::ReadAllText($scConXmp)
    Assert-True (($scConXmpText -match 'xmp:Rating="1"') -and ($scConXmpText -match 'SidecarForExtension="ARW"')) 'SidecarOnly refused to clobber RAW-owned XMP'
    $scReDry = (& $restScript -JpgRoot $scPhotos -CatalogPath $scCat -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -SidecarOnly -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($scReDry -match 'Nothing to do')) 'SidecarOnly second run skips already-matching sidecar'

    # 4e. Universal Sources Test: No-Catalog RAW/XMP (incl. digiKam PickLabel) + Capture One + PixCake + PixPretty + Luminar Neo
    Write-Host "`n=== 4e. Universal Sources Test (No-Catalog XMP + Capture One + PixCake + PixPretty + Luminar Neo) ===" -ForegroundColor Cyan
    $uniRoot   = Join-Path $tmpBase 'uni_test'
    $uniPhotos = Join-Path $uniRoot 'Photos'
    $uXmpDir   = Join-Path $uniPhotos '2026-03-01'
    $uC1Dir    = Join-Path $uniPhotos '2026-03-02'
    $uPxDir    = Join-Path $uniPhotos '2026-03-03'
    $uPpDir    = Join-Path $uniPhotos '2026-03-04'
    $uLumDir   = Join-Path $uniPhotos '2026-03-05'
    $c1Dir     = Join-Path $uniRoot 'Capture One Catalog'
    $pxDbDir   = Join-Path $uniRoot 'pixcake_db\user_1\project_1'
    $pxRootArg = Join-Path $uniRoot 'pixcake_db'
    $ppDbDir   = Join-Path $uniRoot 'pixpretty_cfg\user_1\project'
    $ppRootArg = Join-Path $uniRoot 'pixpretty_cfg'
    $lumDir    = Join-Path $uniRoot 'Luminar Neo Catalog'
    New-Item -ItemType Directory -Path $uXmpDir, $uC1Dir, $uPxDir, $uPpDir, $uLumDir, $c1Dir, $pxDbDir, $ppDbDir, $lumDir -Force | Out-Null

    $uXmpJpg = Join-Path $uXmpDir 'SONY_XMP.JPG'
    New-TestJpg (Join-Path $uXmpDir 'SONY_XMP.ARW') 0
    New-TestJpg $uXmpJpg 0
    New-TestXmp (Join-Path $uXmpDir 'SONY_XMP.xmp') 4 'ARW' 'image/x-sony-arw' 'SONY_XMP.ARW'

    # digiKam PickLabel=3 (Accepted) vs PickLabel=1 (Rejected)
    $dkAccXmp = Join-Path $uXmpDir 'DIGI_ACC.xmp'
    $dkRejXmp = Join-Path $uXmpDir 'DIGI_REJ.xmp'
    [IO.File]::WriteAllText($dkAccXmp, '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description xmlns:digiKam="http://www.digikam.org/ns/1.0/" digiKam:PickLabel="3"/></rdf:RDF></x:xmpmeta>')
    [IO.File]::WriteAllText($dkRejXmp, '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description xmlns:digiKam="http://www.digikam.org/ns/1.0/" digiKam:PickLabel="1"/></rdf:RDF></x:xmpmeta>')
    $dkMap = Get-FileRatingMap -FilePaths @($dkAccXmp, $dkRejXmp) -ExifTool $resolvedEt
    Assert-True ($dkMap[$dkAccXmp] -eq 1 -and $dkMap[$dkRejXmp] -eq 0) 'Get-FileRatingMap treats digiKam PickLabel=3 as picked (1*) and ignores PickLabel=1'

    $uC1Raw = Join-Path $uC1Dir 'C1_RAW.ARW'
    $uC1Jpg = Join-Path $uC1Dir 'C1_RAW.JPG'
    New-TestJpg $uC1Raw 0
    New-TestJpg $uC1Jpg 0

    $uPxRaw = Join-Path $uPxDir 'PX_RAW.ARW'
    $uPxJpg = Join-Path $uPxDir 'PX_RAW.JPG'
    New-TestJpg $uPxRaw 0
    New-TestJpg $uPxJpg 0

    $uPpRaw     = Join-Path $uPpDir 'PP_RAW.ARW'
    $uPpJpg     = Join-Path $uPpDir 'PP_RAW.JPG'
    $uPpFlagRaw = Join-Path $uPpDir 'PP_FLAG.ARW'
    $uPpFlagJpg = Join-Path $uPpDir 'PP_FLAG.JPG'
    $uPpDelRaw  = Join-Path $uPpDir 'PP_DEL.ARW'
    $uPpDelJpg  = Join-Path $uPpDir 'PP_DEL.JPG'
    $uPpDpRaw   = Join-Path $uPpDir 'PP_DELPROJ.ARW'
    $uPpDpJpg   = Join-Path $uPpDir 'PP_DELPROJ.JPG'
    foreach ($p in @($uPpRaw, $uPpJpg, $uPpFlagRaw, $uPpFlagJpg, $uPpDelRaw, $uPpDelJpg, $uPpDpRaw, $uPpDpJpg)) { New-TestJpg $p 0 }

    $uLumRaw   = Join-Path $uLumDir 'LUM_RAW.ARW'
    $uLumJpg   = Join-Path $uLumDir 'LUM_RAW.JPG'
    $uLumTrRaw = Join-Path $uLumDir 'LUM_TRASH.ARW'
    $uLumTrJpg = Join-Path $uLumDir 'LUM_TRASH.JPG'
    foreach ($p in @($uLumRaw, $uLumJpg, $uLumTrRaw, $uLumTrJpg)) { New-TestJpg $p 0 }

    $c1CatPath  = Join-Path $c1Dir 'TestC1.cocatalogdb'
    $pxDbPath   = Join-Path $pxDbDir 'project.db'
    $ppDbPath   = Join-Path $ppDbDir 'projects_v4.db'
    $lumCatPath = Join-Path $lumDir 'TestLum.luminarneo'
    $pyUni      = Join-Path $tmpBase 'mk_uni_dbs.py'
    $uniPyCode = @'
import ctypes, os, sqlite3, sys
c1_path, c1_winroot, px_path, px_img, pp_path, pp_jpg, pp_flag_arw, pp_del_arw, pp_dp_arw, lum_path, lum_dir = sys.argv[1:12]

con1 = sqlite3.connect(c1_path)
c1 = con1.cursor()
c1.execute('CREATE TABLE ZPATHLOCATION (Z_PK INTEGER PRIMARY KEY, ZWINROOT TEXT, ZRELATIVEPATH TEXT)')
c1.execute('CREATE TABLE ZIMAGE (Z_PK INTEGER PRIMARY KEY, ZIMAGELOCATION INTEGER, ZIMAGEFILENAME TEXT, ZISTRASHED INTEGER)')
c1.execute('CREATE TABLE ZVARIANT (Z_PK INTEGER PRIMARY KEY, ZIMAGE INTEGER)')
c1.execute('CREATE TABLE ZVARIANTLAYER (Z_PK INTEGER PRIMARY KEY, ZVARIANT INTEGER)')
c1.execute('CREATE TABLE ZVARIANTMETADATA (Z_PK INTEGER PRIMARY KEY, ZLAYER INTEGER, ZBASIC_RATING INTEGER)')
c1.execute("INSERT INTO ZPATHLOCATION VALUES (1, ?, '2026-03-02')", (c1_winroot,))
c1.execute("INSERT INTO ZIMAGE VALUES (1, 1, 'C1_RAW.ARW', 0)")
c1.execute("INSERT INTO ZVARIANT VALUES (1, 1)")
c1.execute("INSERT INTO ZVARIANTLAYER VALUES (1, 1)")
c1.execute("INSERT INTO ZVARIANTMETADATA VALUES (1, 1, 5)")
con1.commit()
con1.close()

con2 = sqlite3.connect(px_path)
c2 = con2.cursor()
c2.execute('CREATE TABLE thumbnail (id INTEGER PRIMARY KEY, originalImagePath TEXT, starLevel INTEGER, selectFlag INTEGER, isFavourite INTEGER, inRecycleBin INTEGER)')
c2.execute("INSERT INTO thumbnail VALUES (1, ?, 3, 0, 0, 0)", (px_img,))
con2.commit()
con2.close()

k32 = ctypes.windll.kernel32
drv = os.path.splitdrive(pp_jpg)[0] + '\\'
vbuf = ctypes.create_unicode_buffer(128)
vol_guid = drv
if k32.GetVolumeNameForVolumeMountPointW(drv, vbuf, 128):
    vol_guid = vbuf.value
ser = ctypes.c_ulong(0)
k32.GetVolumeInformationW(drv, None, 0, ctypes.byref(ser), None, None, None, 0)
vsn_json = f'{{"VolumeSerialNumber":"{ser.value:08X}"}}'

def rel_from_drive(p):
    return p[3:].replace('\\', '/')

con3 = sqlite3.connect(pp_path)
c3 = con3.cursor()
c3.execute('CREATE TABLE projects (project_id TEXT PRIMARY KEY, name TEXT, del_states INTEGER)')
c3.execute('CREATE TABLE images (img_no TEXT PRIMARY KEY, project_id TEXT, name TEXT, relative_path TEXT, root_path_id TEXT, level INTEGER, flag_mark INTEGER, color_mark INTEGER, is_del INTEGER)')
c3.execute("INSERT INTO projects VALUES ('p_active', 'active', 0)")
c3.execute("INSERT INTO projects VALUES ('p_deleted', 'deleted', 2)")
c3.execute("INSERT INTO images VALUES ('i1', 'p_active', 'PP_RAW.JPG', ?, ?, 2, 0, 0, 0)", (rel_from_drive(pp_jpg), vol_guid))
c3.execute("INSERT INTO images VALUES ('i2', 'p_active', 'PP_FLAG.ARW', ?, ?, 0, 1, 0, 0)", (rel_from_drive(pp_flag_arw), vol_guid))
c3.execute("INSERT INTO images VALUES ('i3', 'p_active', 'PP_DEL.ARW', ?, ?, 5, 0, 0, 1)", (rel_from_drive(pp_del_arw), vol_guid))
c3.execute("INSERT INTO images VALUES ('i4', 'p_deleted', 'PP_DELPROJ.ARW', ?, ?, 5, 0, 0, 0)", (rel_from_drive(pp_dp_arw), vol_guid))
con3.commit()
con3.close()

con4 = sqlite3.connect(lum_path)
c4 = con4.cursor()
c4.execute('CREATE TABLE volumes (_id_int_64 INTEGER PRIMARY KEY, marked_to_delete_bool INTEGER, guid_wide_ch TEXT, info_wide_ch TEXT)')
c4.execute('CREATE TABLE paths (_id_int_64 INTEGER PRIMARY KEY, marked_to_delete_bool INTEGER, volume_id_int_64 INTEGER, path_wide_ch TEXT)')
c4.execute('CREATE TABLE paths_images (_key_id_int_64 INTEGER, _val_id_int_64 INTEGER)')
c4.execute('CREATE TABLE images (_id_int_64 INTEGER PRIMARY KEY, marked_to_delete_bool INTEGER, path_wide_ch TEXT)')
c4.execute('CREATE TABLE image_user_attributes (_id_int_64 INTEGER PRIMARY KEY, marked_to_delete_bool INTEGER, _out_id_int_64 INTEGER, trash_bool INTEGER, marker INTEGER, color INTEGER, rating INTEGER)')
c4.execute("INSERT INTO volumes VALUES (1, 0, 'g1', ?)", (vsn_json,))
c4.execute("INSERT INTO paths VALUES (1, 0, 1, ?)", (rel_from_drive(lum_dir),))
c4.execute("INSERT INTO images VALUES (1, 0, 'LUM_RAW.ARW')")
c4.execute("INSERT INTO images VALUES (2, 0, 'LUM_TRASH.ARW')")
c4.execute("INSERT INTO paths_images VALUES (1, 1)")
c4.execute("INSERT INTO paths_images VALUES (1, 2)")
c4.execute("INSERT INTO image_user_attributes VALUES (1, 0, 1, 0, 0, 0, 4)")
c4.execute("INSERT INTO image_user_attributes VALUES (2, 0, 2, 1, 0, 0, 5)")
con4.commit()
con4.close()
'@
    [IO.File]::WriteAllText($pyUni, $uniPyCode, (New-Object System.Text.UTF8Encoding $false))
    & $pyExe $pyUni $c1CatPath $uniPhotos $pxDbPath $uPxRaw $ppDbPath $uPpJpg $uPpFlagRaw $uPpDelRaw $uPpDpRaw $lumCatPath $uLumDir
    if ($LASTEXITCODE -ne 0) { throw "Failed to create C1/PixCake/PixPretty/Luminar test DBs: exit=$LASTEXITCODE" }

    # Zero-catalog test: Sony XMP 4* syncs to JPG without ANY DB
    & $restScript -JpgRoot $uniPhotos -SubFolder '2026-03-01' -NoCatalog -ExifToolPath $resolvedEt -NoBackup -NoConfirm -Lang en
    Assert-True ($LASTEXITCODE -eq 0) 'Restore-RatingToJpg works with -NoCatalog via companion RAW/XMP'
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $uXmpMeta = (& $resolvedEt -json -XMP:Rating $uXmpJpg 2>$null) | Out-String | ConvertFrom-Json
    } finally { $ErrorActionPreference = $prev }
    Assert-True ($uXmpMeta[0].Rating -eq 4) 'No-catalog JPG received 4-star rating from companion .xmp'

    # Capture One DB test: protects ARW in clean AND syncs 5* to JPG
    $c1CleanOut = (& $cleanScript -RootPath $uniPhotos -CatalogPath $c1CatPath -ExifToolPath $resolvedEt -BeforeDate '2026-04-01' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($c1CleanOut -notmatch 'C1_RAW\.ARW') -and ($c1CleanOut -match 'PX_RAW\.ARW') -and ($c1CleanOut -match 'Kept \(star-rated\)\s*:\s*2')) 'Clean-RawToRecycleBin protects Capture One rated RAW'
    & $restScript -JpgRoot $uniPhotos -SubFolder '2026-03-02' -CatalogPath $c1CatPath -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -NoBackup -NoConfirm -Lang en
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $uC1Meta = (& $resolvedEt -json -XMP:Rating $uC1Jpg 2>$null) | Out-String | ConvertFrom-Json
    } finally { $ErrorActionPreference = $prev }
    Assert-True ($uC1Meta[0].Rating -eq 5) 'Capture One 5-star synced to C1_RAW.JPG'

    # PixCake DB test: protects ARW in clean AND syncs 3* to JPG
    $pxCleanOut = (& $cleanScript -RootPath $uniPhotos -ExifToolPath $resolvedEt -BeforeDate '2026-04-01' -PixCakeDbRoot $pxRootArg -PixPrettyDbRoot 'NONE' -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($pxCleanOut -notmatch 'PX_RAW\.ARW') -and ($pxCleanOut -match 'Kept \(star-rated\)\s*:\s*4')) 'Clean-RawToRecycleBin protects PixCake rated RAW'
    & $restScript -JpgRoot $uniPhotos -SubFolder '2026-03-03' -PixCakeDbRoot $pxRootArg -PixPrettyDbRoot 'NONE' -ExifToolPath $resolvedEt -NoBackup -NoConfirm -Lang en
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $uPxMeta = (& $resolvedEt -json -XMP:Rating $uPxJpg 2>$null) | Out-String | ConvertFrom-Json
    } finally { $ErrorActionPreference = $prev }
    Assert-True ($uPxMeta[0].Rating -eq 3) 'PixCake 3-star synced to PX_RAW.JPG'

    # PixPretty DB test: protects active rated/flagged ARWs, targets deleted/deleted-project ARWs, and syncs to JPG
    $ppCleanOut = (& $cleanScript -RootPath $uniPhotos -ExifToolPath $resolvedEt -BeforeDate '2026-04-01' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot $ppRootArg -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($ppCleanOut -notmatch 'PP_RAW\.ARW') -and ($ppCleanOut -notmatch 'PP_FLAG\.ARW') -and ($ppCleanOut -match 'PP_DEL\.ARW') -and ($ppCleanOut -match 'PP_DELPROJ\.ARW')) 'Clean-RawToRecycleBin protects PixPretty active rated/flagged RAWs and excludes deleted items'
    & $restScript -JpgRoot $uniPhotos -SubFolder '2026-03-04' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot $ppRootArg -ExifToolPath $resolvedEt -NoBackup -NoConfirm -Lang en
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $uPpMeta = (& $resolvedEt -json -XMP:Rating $uPpJpg $uPpFlagJpg $uPpDelJpg $uPpDpJpg 2>$null) | Out-String | ConvertFrom-Json
    } finally { $ErrorActionPreference = $prev }
    Assert-True ($uPpMeta[0].Rating -eq 2 -and $uPpMeta[1].Rating -eq 1 -and $null -eq $uPpMeta[2].Rating -and $null -eq $uPpMeta[3].Rating) 'PixPretty 2* & flag synced to JPG while recycled/deleted-project stayed unrated'

    # Luminar Neo DB test: protects non-trashed rated RAW and syncs 4* to JPG
    $lumCleanOut = (& $cleanScript -RootPath $uniPhotos -CatalogPath $lumCatPath -ExifToolPath $resolvedEt -BeforeDate '2026-04-01' -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -DryRun -Lang en 6>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0 -and ($lumCleanOut -notmatch 'LUM_RAW\.ARW') -and ($lumCleanOut -match 'LUM_TRASH\.ARW')) 'Clean-RawToRecycleBin protects Luminar Neo rated RAW and excludes Trash'
    & $restScript -JpgRoot $uniPhotos -SubFolder '2026-03-05' -CatalogPath $lumCatPath -ExifToolPath $resolvedEt -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -NoBackup -NoConfirm -Lang en
    $prev = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $uLumMeta = (& $resolvedEt -json -XMP:Rating $uLumJpg $uLumTrJpg 2>$null) | Out-String | ConvertFrom-Json
    } finally { $ErrorActionPreference = $prev }
    Assert-True ($uLumMeta[0].Rating -eq 4 -and $null -eq $uLumMeta[1].Rating) 'Luminar Neo 4-star synced to LUM_RAW.JPG while trashed stayed unrated'

    Write-Host "`n=== 5. Unified Menu Smoke Test (-Lang zh & -Lang en & live L toggle) ===" -ForegroundColor Cyan
    $menuScript = Join-Path $projectRoot 'scripts\Start-Toolkit.ps1'
    foreach ($lg in @('zh', 'en')) {
        $mOut = (& $menuScript -RootPath $e2ePhotos -ExifToolPath $resolvedEt -CatalogPath $e2eCat -PixCakeDbRoot 'NONE' -PixPrettyDbRoot 'NONE' -Lang $lg -NoConfig -AutoChoices @('L', '0') 6>&1 | Out-String)
        Write-Host $mOut
        Assert-True (($mOut -notmatch '\{0\}') -and ($mOut -match 'ExifTool') -and ($mOut -match 'Rollback') -and ($mOut -match 'RAW & JPG 摄影清理与星标工具箱') -and ($mOut -match 'RAW & JPG Photo Toolkit')) ("Start-Toolkit.ps1 -Lang $lg shows env checks, toggles lang, and exits cleanly")
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

<#
.SYNOPSIS
  Shared helpers for lightroom-raw-toolkit (i18n, RAW registry, path discovery,
  Lightroom catalog dual-backend reader, sidecar ownership, ExifTool scanner).
  Must be saved as UTF-8 with BOM for Windows PowerShell 5.1 compatibility.
#>

$script:UiLang = 'en'

$script:LrtMessages = @{
    en = @{
        ErrNoVisualBasic      = '[ERROR] Cannot load Microsoft.VisualBasic. Please run on Windows PowerShell 5.1+.'
        ErrNoRoot             = '[ERROR] Photo root folder not found: {0}'
        ErrNoJpgRoot          = '[ERROR] JPG root folder not found: {0}'
        ErrNoExifTool         = '[ERROR] exiftool.exe not found: {0}'
        ErrNoExifToolHint1    = '        exiftool is required to read star ratings (rated files are kept by default).'
        ErrNoExifToolHint2    = '        Place exiftool.exe in tools\, install it in PATH, or pass -DeleteRated.'
        ErrNoExifToolJpg      = '[ERROR] exiftool.exe not found in tools\, script dir, or PATH.'
        ErrNoCatalog          = '[ERROR] Lightroom catalog not found: {0}'
        ErrBothDateFlags      = '[ERROR] Use either -BeforeDate or -KeepRecentDays, not both.'
        ErrInvalidDays        = '[ERROR] Invalid number of days: {0}'
        ErrInvalidChoice      = "[ERROR] Invalid selection '{0}'. Enter 1 or 2."
        ErrBadDate            = '[ERROR] Invalid date format (expected yyyy-MM-dd): {0}'
        ErrDaysMin            = '[ERROR] KeepRecentDays must be >= 1.'
        ErrNoRawExt           = '[ERROR] -RawExtensions cannot be empty.'
        ErrNoSqliteReader     = 'Neither sqlite3.exe nor Python 3 was found to read Lightroom catalog: {0}'
        ErrCatalogRead        = 'Failed to read Lightroom catalog ({0}). Close Lightroom and retry: {1}'
        ErrCatalogAbort       = '        Aborted for safety. Close Lightroom and retry, or pass -NoCatalog to skip.'
        WarnInvalidDateFolder = '[WARN] Skipping invalid date folder name: {0}'
        WarnLrRunning1        = '[WARN] Lightroom appears to be running (.lrcat.lock detected)!'
        WarnLrRunning2        = '       Recent ratings may still be in memory/WAL; close Lightroom first to be safe.'
        WarnNoXmp1            = '[WARN] {0} target folder(s) have NO .xmp sidecars and 0 rated files!'
        WarnNoXmp2            = '       If you rated photos in Lightroom without pressing Ctrl+S, they WILL BE DELETED!'
        WarnDeleteRawOnly     = '[WARN] -DeleteRawOnly is enabled: {0} target RAW file(s) have NO companion JPG/HIF!'
        TipLargeRecycle       = '[TIP] About {0} will be moved to the Recycle Bin (>= 20 GB). Check Recycle Bin quota if needed.'
        WarnWriteLog          = '[WARN] Could not write log file {0}: {1}'
        BannerTitle           = '===== RAW Cleanup Tool (moves to Recycle Bin) ====='
        BannerDefaultRoot     = 'Default folder: {0}'
        PromptCustomRoot      = 'Photo folder (press Enter for default, or drop a folder path)'
        BannerSwitchedRoot    = 'Switched folder: {0}'
        PromptMode            = 'Mode: [1] Cutoff date (older than date)  [2] Keep last N days  (0/Enter = cancel)'
        PromptChoice          = 'Enter choice (0/Enter = cancel)'
        PromptDays            = 'Keep last how many days (incl. today, e.g. 90; 0/Enter = cancel)'
        PromptBeforeDate      = 'Cutoff date yyyy-MM-dd (strictly earlier will be cleaned, e.g. 2026-04-01; 0/Enter = cancel)'
        NonDateFoundNotice    = '[INFO] No yyyy-MM-dd* date subfolders found here, but {0} RAW file(s) exist.'
        NonDateSwitchPrompt   = 'Type Y + Enter to scan recursively by file modification date (-UseFileDate); Enter/0 = cancel'
        NonDateHintCli        = '[TIP] No yyyy-MM-dd* subfolders found here ({0} RAW file(s) exist). Pass -UseFileDate to scan by file LastWriteTime.'
        RuleBefore            = 'clean items earlier than {0} (excl.)'
        RuleRecent            = 'keep {0} .. today ({1} days), clean older'
        HeaderRoot            = ' Root    : {0}'
        HeaderExts            = ' RAW Exts: {0}'
        HeaderScope           = ' Scope   : {0}'
        ScopeDateFolders      = 'date-prefixed folders (yyyy-MM-dd*)'
        ScopeFileDate         = 'all files by LastWriteTime (-UseFileDate)'
        HeaderRule            = ' Rule    : {0}'
        HeaderRating          = ' Rating  : {0}'
        RatingDelete          = 'DELETE star-rated files too (-DeleteRated)'
        RatingKeep            = 'KEEP star-rated files (RAW + XMP + JPG/HIF + software DBs)'
        HeaderRawOnly         = ' RAW-only: {0}'
        RawOnlyDelete         = 'DELETE RAW-only files too (-DeleteRawOnly)'
        RawOnlyKeep           = 'KEEP RAW-only files (no companion JPG/HIF)'
        HeaderCatalog         = ' Databases: {0}'
        CatSkipped            = 'skipped (-DeleteRated)'
        CatDisabled           = 'disabled (-NoCatalog)'
        CatNotFound           = 'none found (ExifTool checks RAW / XMP / JPG)'
        HeaderMode            = ' Mode    : {0}'
        ModeDryRun            = '[DRY-RUN: nothing will be deleted]'
        ModeLive              = '[LIVE: will move to Recycle Bin after confirmation]'
        StatusReadingCatalog  = '  Reading star ratings from photo software database(s)...'
        StatusLoadedCatalog   = '  Loaded {0} rated/picked entry(ies) from database(s).'
        StatusLoadedDbItem    = '    + {0}: {1} rated/picked entry(ies)'
        StatusReadingExif     = '  Reading star ratings via ExifTool ({0}/{1})...'
        NothingAllKept        = 'All {0} candidate RAW file(s) are protected and kept (rated: {1}, unreadable: {2}, raw-only: {3}).'
        NothingFound          = 'No matching RAW files found. Nothing to do.'
        PreviewHeader         = 'PREVIEW - these RAW file(s) will be moved to the Recycle Bin ({0} group(s), {1} file(s)):'
        FlatBucketName        = '(All folders / file-date mode)'
        FlagNoXmpZero         = 'NO-XMP/0-RATED'
        FlagNoXmp             = 'NO-XMP'
        FlagKeepRawOnly       = 'KEEP-RAW-ONLY:{0}'
        FlagDelRawOnly        = 'DEL-RAW-ONLY:{0}'
        PreviewLine           = '  {0}   del {1,4}   keep {2,3}   {3,9}{4}'
        PreviewTotalSize      = '  Estimated space freed: {0}'
        PreviewFormats        = '  RAW formats            : {0}'
        PreviewSidecars       = '  Sidecar XMPs to recycle: {0}'
        PreviewAcrs           = '  ACR caches to recycle  : {0}'
        PreviewKeptRated      = '  Kept (star-rated)      : {0} (in above groups: {1}, older groups: {2}, DB hits: {3})'
        PreviewKeptUnknown    = '  Kept (unreadable)      : {0}'
        PreviewKeptRawOnly    = '  Kept (RAW-only)        : {0}'
        PreviewSampleHeader   = '  File preview (showing first {0} of {1}):'
        PreviewSampleMore     = '    ... ({0} more omitted; type V below to view full list)'
        PreviewAllHeader      = '--- Full File List ({0} item(s)) ---'
        PreviewAllEnd         = '--- End of File List ---'
        ConfirmNote           = 'The list above is a PREVIEW. Nothing has been deleted yet.'
        ConfirmPrompt         = 'Type Y + Enter to move to Recycle Bin | V = view all files | Enter = cancel'
        Cancelled             = 'Cancelled. No files were touched. (Preview only: pass -DryRun.)'
        ProgressActivity      = 'Processing RAW files'
        DoneHeader            = '================ Done ================'
        DoneDrySummary        = 'Dry-run complete: {0} file(s) targeted, about {1}.'
        DoneDryKeptRated      = 'Protected and kept {0} star-rated file(s).'
        DoneDryKeptUnknown    = 'Protected and kept {0} unreadable file(s).'
        DoneDryKeptRawOnly    = 'Protected and kept {0} RAW-only file(s).'
        DoneDryHint           = 'Re-run without -DryRun and type Y at the prompt to really recycle.'
        DoneLiveSummary       = 'Recycled {0} file(s), freed about {1}.'
        DoneLiveKeptRated     = 'Kept {0} star-rated file(s).'
        DoneLiveKeptUnknown   = 'Kept {0} unreadable file(s).'
        DoneLiveKeptRawOnly   = 'Kept {0} RAW-only file(s).'
        DoneFailed            = 'Failed ({0}):'
        DoneLogPath           = 'Log file: {0}'
        JpgBanner             = '===== Sync Star Ratings to JPG ====='
        JpgCatalog            = ' DBs     : {0}'
        JpgDbNone             = 'none (reading companion RAW / .xmp files)'
        JpgSourceLine         = ' Source  : {0}'
        JpgSourceAuto         = 'Auto (Software DBs + companion RAW / .xmp)'
        JpgSourceDbOnly       = 'Software DBs only (-RatingSource db)'
        JpgSourceFilesOnly    = 'Companion RAW / .xmp files only (-RatingSource files)'
        JpgRoot               = ' JPG Root: {0}'
        JpgExifTool           = ' ExifTool: {0}'
        JpgPromptTarget       = 'Write mode: [1] Embed into JPG (Win/Albums/LR visible)  [2] Write .xmp sidecar only (zero JPG changes)  (0/Enter = cancel)'
        JpgPromptScope        = 'Scope: [1] All folders under root  [2] Recent N days  [3] Single subfolder  (0/Enter = cancel)'
        JpgPromptRecentDays   = 'Recent how many days (incl. today, e.g. 30; 0/Enter = cancel)'
        JpgPromptSubFolder    = 'Subfolder name or relative path (e.g. 2026-11-22; 0/Enter = cancel)'
        ErrNoSubFolder        = '[ERROR] Subfolder not found: {0}'
        ErrInvalidScopeChoice = "[ERROR] Invalid selection '{0}'. Enter 1, 2, or 3."
        JpgScopeLine          = ' Scope   : {0}'
        JpgScopeAll           = 'all folders'
        JpgScopeRecent        = 'recent {0} day(s) (>= {1})'
        JpgScopeSubFolder     = 'subfolder {0}'
        JpgModeDry            = ' Mode    : [DRY-RUN: preview only, no files will be modified]'
        JpgModeLiveJpgBackup  = ' Mode    : [LIVE -> JPG: preserve mtime (-P), centralized backup -> {0}]'
        JpgModeLiveJpgNoBackup= ' Mode    : [LIVE -> JPG: preserve mtime (-P), in-place overwrite (-NoBackup)]'
        JpgModeLiveSidecar    = ' Mode    : [LIVE -> .xmp sidecar only: JPG bytes untouched]'
        JpgReadingCat         = 'Reading star ratings from software DBs & companion files...'
        JpgReadingRawXmp      = 'Scanning {0} companion RAW / .xmp file(s) via ExifTool...'
        JpgLoadedCat          = 'Loaded {0} folder+name star rating(s) for matching JPGs.'
        JpgNoRatings          = '[INFO] No star ratings found from DBs or companion RAW/.xmp files. Nothing to sync.'
        JpgNoFiles            = '[INFO] No JPG files found under {0}.'
        JpgFoundFiles         = 'Found {0} JPG file(s).'
        JpgScanningExisting   = 'Checking existing ratings on {0} matched file(s) via ExifTool...'
        JpgNothingToWrite     = 'All {0} matched JPG(s) already have the target star rating (skipped: {1}, unmatched: {2}). Nothing to do.'
        JpgPreviewHeader      = 'PREVIEW - {0} file(s) will be written across {1} folder(s):'
        JpgPreviewLine        = '  {0}   new {1,4}   upd {2,3}   skip {3,4}{4}'
        JpgPreviewFlagConflict= 'XMP-CONFLICT:{0}'
        JpgPreviewFlagUnread  = 'UNREADABLE:{0}'
        JpgPreviewSkippedDirs = '  + {0} folder(s) with {1} matched JPG(s) already at identical rating (auto-skipped, untouched).'
        JpgPreviewTotals      = '  To write: {0} (new: {1}, update: {2})   Skipped same: {3}   Unmatched: {4}'
        JpgPreviewExtraSkips  = '  Safety skips: XMP ownership conflict = {0}, unreadable = {1}'
        JpgSampleItem         = '    {0}   ->  {1} star(s) [{2}]'
        JpgStatusNew          = 'new'
        JpgStatusUpd          = 'update'
        JpgWarnCloud1         = '[NOTICE] Writing ratings into JPG modifies EXIF/XMP bytes (size & hash change).'
        JpgWarnCloud2         = '         Cloud drives may re-upload the {0} modified JPG(s) ({1} same-star JPG(s) stay untouched).'
        JpgWarnCloud3         = '         Backups are stored outside your photo folder (no .jpg_original clutter). Use -SidecarOnly to never touch JPGs.'
        JpgWarnSidecar1       = '[INFO] Sidecar-only mode: JPG bytes will NOT be modified (zero cloud re-upload of JPGs).'
        JpgWarnSidecar2       = '       Lightroom / Bridge read JPG .xmp sidecars, while Windows Explorer & most cloud albums do not.'
        JpgConfirmNote        = 'The list above is a PREVIEW. No files have been modified yet.'
        JpgConfirmPrompt      = 'Type Y + Enter to write ratings | V = view all files | Enter = cancel'
        JpgCancelled          = 'Cancelled. No files were modified. (Preview only: pass -DryRun.)'
        JpgBackingUp          = 'Backing up {0} original JPG(s) to {1}...'
        JpgBackupFail         = '[FAIL] Backup failed (skipped writing for safety): {0} -> {1}'
        JpgWritingBatch       = 'Writing {0} star(s) to {1} JPG file(s)...'
        JpgWritingSidecar     = 'Writing {0} star(s) to {1} .xmp sidecar(s)...'
        JpgWriteFail          = '[FAIL] {0}-star batch ({1}..{2}): {3}'
        JpgWriteOk            = '[OK]   updated {0} file(s) -> {1} star(s)'
        JpgSummaryHeader      = '================ Summary ================'
        JpgSummaryCounts      = 'Written: {0}   Skipped (same): {1}   Skipped (safety): {2}   No rating: {3}   Failed: {4}'
        JpgDryDone            = 'Dry-run complete. Nothing was modified.'
        JpgDryHint            = 'Re-run without -DryRun and type Y at the prompt to apply changes.'
        JpgDoneBackupPath     = 'Centralized backups saved to: {0}'
        JpgDoneNoBackup       = 'Modified in place (-NoBackup) with original modification times preserved (-P).'
        JpgDoneSidecar        = 'Sidecar .xmp files written; original JPG files were NOT modified.'
        JpgWriteNext          = 'Next: In Lightroom, select JPGs -> Ctrl+Shift+R to reload metadata if needed.'
        RbBanner              = '===== Rollback JPG Backups (Restore Originals) ====='
        RbNoBackups           = '[INFO] No JPG restore backups found under {0}.'
        RbListHeader          = 'Available backups (newest first):'
        RbListItem            = '  [{0}] {1}  ({2} file(s), {3} -> {4})'
        RbSelectPrompt        = 'Select backup number to restore (0/Enter = cancel)'
        RbInvalidSel          = "[ERROR] Invalid selection '{0}'."
        RbErrNoDir            = '[ERROR] Backup directory not found: {0}'
        RbErrNoTargetRoot     = '[ERROR] Target JPG root not found in manifest.json. Pass -JpgRoot explicitly.'
        RbErrEmpty            = '[INFO] No backup JPG files found inside {0}.'
        RbPreviewInfo         = ' Backup  : {0}'
        RbTargetInfo          = ' Target  : {0}'
        RbFileCount           = ' Files   : {0} original JPG(s), {1} will be restored (exact bytes & modification time)'
        RbConfirmNote         = 'This will overwrite the modified JPGs in the target folder with their original backups.'
        RbConfirmPrompt       = 'Type Y + Enter to REALLY rollback | V = view all files | Enter = cancel'
        RbCancelled           = 'Rollback cancelled. No files were modified.'
        RbDryDone             = 'Dry-run complete. No files were modified.'
        RbFailItem            = '[FAIL] {0} -> {1}'
        RbDoneSummary         = 'Rollback complete: restored {0} file(s), failed {1}.'
        RbPromptRemoveBackup  = 'Rollback succeeded. Delete this backup folder ({0}) to free space? [y/N] (Enter = keep)'
        RbBackupKept          = 'Backup folder kept at: {0}'
        RbBackupRemoved       = 'Removed backup folder: {0}'
        RbCloudTip            = 'Tip: If your cloud drive still shows pending uploads, pause & resume sync to refresh.'
        MenuTitle             = '=========== RAW & JPG Photo Toolkit ==========='
        MenuCurrentRoot       = ' Photo folder: {0}'
        MenuCurrentLang       = ' Language    : {0}'
        MenuEnvExifOk         = ' ExifTool    : OK ({0})'
        MenuEnvExifMissing    = ' ExifTool    : NOT FOUND (place exiftool.exe in tools\)'
        MenuEnvCatOk          = ' LR Catalog  : {0}'
        MenuEnvCatLocked      = ' LR Catalog  : {0}  [Lightroom is running!]'
        MenuEnvCatMissing     = ' Databases   : none found (ExifTool still reads RAW / XMP / JPG ratings)'
        MenuEnvDbFound        = ' Databases   : {0}'
        MenuEnvNoSqlite       = ' [WARN] Neither sqlite3.exe nor Python 3 found; catalog DB reading unavailable.'
        MenuOptClean          = '  [1] Clean unrated RAW files (move to Recycle Bin)'
        MenuOptRestore        = '  [2] Sync star ratings to JPG (LR / C1 / PixCake / PixPretty / XMP)'
        MenuOptRollback       = '  [3] Rollback JPG backups (restore exact original JPGs)'
        MenuOptSwitchRoot     = '  [4] Switch target photo folder'
        MenuOptInstallEt      = '  [I] Auto-download & install ExifTool into tools\'
        MenuOptSwitchLang     = '  [L] Switch language (English / 中文)'
        MenuOptExit           = '  [0] Exit'
        MenuPrompt            = 'Select an option'
        MenuInvalidOpt        = "[WARN] Invalid option '{0}'."
        MenuPressEnter        = 'Press Enter to return to menu...'
        MenuSwitchRootPrompt  = 'Enter or drop photo folder path (Enter = keep current)'
        MenuEtMissingStartup  = '[INFO] ExifTool is not installed yet (needed to read/write photo ratings).'
        MenuEtAutoInstallPrompt = 'Auto-download and set up latest ExifTool into tools\ now? [Y/n] (Enter = Yes)'
        EtInstBanner          = '===== Auto-Install ExifTool (Official Windows 64-bit) ====='
        EtInstFetchingVer     = 'Checking latest ExifTool download URL from exiftool.org...'
        EtInstDownloading     = 'Downloading: {0}'
        EtInstExtracting      = 'Extracting and configuring into {0}...'
        EtInstOk              = '[OK] ExifTool {0} installed successfully at {1}'
        EtInstFail            = '[ERROR] ExifTool auto-install failed: {0}'
        EtInstManualHint      = 'Alternative: run "winget install OliverBetz.ExifTool" or download manually from https://exiftool.org/'
        EtInstBadZip          = 'Downloaded file is not a valid ZIP archive (network proxy/block?).'
        EtInstNoExeInZip      = 'Could not find exiftool(-k).exe or exiftool.exe inside the archive.'
        MenuBye               = 'Goodbye!'
    }
    zh = @{
        ErrNoVisualBasic      = '[错误] 无法加载 Microsoft.VisualBasic 组件，请使用 Windows PowerShell 5.1+ 运行。'
        ErrNoRoot             = '[错误] 找不到照片根目录: {0}'
        ErrNoJpgRoot          = '[错误] 找不到 JPG 根目录: {0}'
        ErrNoExifTool         = '[错误] 找不到 exiftool.exe: {0}'
        ErrNoExifToolHint1    = '       默认需要 exiftool 检测星标（以保留打星照片）。'
        ErrNoExifToolHint2    = '       请将 exiftool.exe 放在 tools\ 目录、加入 PATH，或传入 -DeleteRated。'
        ErrNoExifToolJpg      = '[错误] 未在 tools\、脚本目录或系统 PATH 中找到 exiftool.exe。'
        ErrNoCatalog          = '[错误] 找不到 Lightroom 目录: {0}'
        ErrBothDateFlags      = '[错误] -BeforeDate 和 -KeepRecentDays 不能同时使用。'
        ErrInvalidDays        = '[错误] 天数格式无效: {0}'
        ErrInvalidChoice      = "[错误] 输入无效 '{0}'，请输入 1 或 2。"
        ErrBadDate            = '[错误] 日期格式错误（应为 yyyy-MM-dd）: {0}'
        ErrDaysMin            = '[错误] 保留天数必须 >= 1。'
        ErrNoRawExt           = '[错误] -RawExtensions 不能为空。'
        ErrNoSqliteReader     = '未找到 sqlite3.exe 或 Python 3，无法读取 Lightroom 目录: {0}'
        ErrCatalogRead        = '读取 Lightroom 目录失败 ({0})，请先关闭 Lightroom 后重试: {1}'
        ErrCatalogAbort       = '       为保证安全已中止。请关闭 Lightroom 后重试；如确定跳过，请加 -NoCatalog。'
        WarnInvalidDateFolder = '[警告] 跳过无效日期文件夹名: {0}'
        WarnLrRunning1        = '[警告] 检测到 Lightroom 正在运行（存在 .lrcat.lock）！'
        WarnLrRunning2        = '       刚打的星可能尚未写入主数据库，强烈建议先关闭 Lightroom 再操作！'
        WarnNoXmp1            = '[警告] 有 {0} 个待清理分组既没有 .xmp 文件，也没有检测到任何打星照片！'
        WarnNoXmp2            = '       如果你在 Lightroom 中打过星但未按 Ctrl+S 保存元数据，这些打星照片将被删除！'
        WarnDeleteRawOnly     = '[警告] 已开启 -DeleteRawOnly，待清理文件中有 {0} 个无同名 JPG/HIF 的纯 RAW！'
        TipLargeRecycle       = '[提示] 本次预计移入回收站约 {0}（超过 20 GB），若磁盘回收站配额较小，旧回收站文件可能被系统自动永久挤出，建议留意或分批清理。'
        WarnWriteLog          = '[警告] 写入日志文件失败 {0}: {1}'
        BannerTitle           = '===== RAW 无星标文件清理工具 (移至回收站) ====='
        BannerDefaultRoot     = '默认目录: {0}'
        PromptCustomRoot      = '照片目录（直接回车使用默认，或拖入其他文件夹）'
        BannerSwitchedRoot    = '已切换目录: {0}'
        PromptMode            = '清理模式: [1] 按截止日期（删除早于该日期的）  [2] 保留最近 N 天（0 或直接回车 = 取消）'
        PromptChoice          = '请输入编号（0 或直接回车 = 取消）'
        PromptDays            = '保留最近多少天（含今天，例如 90；0 或直接回车 = 取消）'
        PromptBeforeDate      = '请输入截止日期 yyyy-MM-dd（早于该日期将被清理，例如 2026-04-01；0 或直接回车 = 取消）'
        NonDateFoundNotice    = '[提示] 当前目录未发现 yyyy-MM-dd* 日期子文件夹，但检测到 {0} 个 RAW 文件。'
        NonDateSwitchPrompt   = '输入 Y + 回车 改按文件修改日期递归扫描 (-UseFileDate)；直接回车或 0 = 取消'
        NonDateHintCli        = '[提示] 当前目录没有 yyyy-MM-dd* 日期子文件夹（检测到 {0} 个 RAW），可加 -UseFileDate 按文件修改日期扫描。'
        RuleBefore            = '清理早于 {0} 的项目（不含当天）'
        RuleRecent            = '保留 {0} .. 今天（共 {1} 天），清理更早的'
        HeaderRoot            = ' 根目录  : {0}'
        HeaderExts            = ' RAW 格式: {0}'
        HeaderScope           = ' 扫描范围: {0}'
        ScopeDateFolders      = '日期前缀文件夹 (yyyy-MM-dd*)'
        ScopeFileDate         = '全部文件按修改日期 (-UseFileDate)'
        HeaderRule            = ' 清理规则: {0}'
        HeaderRating          = ' 星标策略: {0}'
        RatingDelete          = '连同打星文件一起删除 (-DeleteRated)'
        RatingKeep            = '保留打星文件（检查 RAW + XMP + JPG/HIF + 软件图库）'
        HeaderRawOnly         = ' 纯 RAW  : {0}'
        RawOnlyDelete         = '连同纯 RAW 一起删除 (-DeleteRawOnly)'
        RawOnlyKeep           = '保留无同名 JPG/HIF 的纯 RAW'
        HeaderCatalog         = ' 软件图库: {0}'
        CatSkipped            = '已跳过 (-DeleteRated)'
        CatDisabled           = '已禁用 (-NoCatalog)'
        CatNotFound           = '未发现（由 ExifTool 直接检查 RAW / XMP / JPG）'
        HeaderMode            = ' 运行模式: {0}'
        ModeDryRun            = '[预览模式：不会删除任何文件]'
        ModeLive              = '[正式模式：确认后移至回收站]'
        StatusReadingCatalog  = '  正在读取摄影软件数据库星标...'
        StatusLoadedCatalog   = '  已从软件图库合计加载 {0} 条打星/标记记录。'
        StatusLoadedDbItem    = '    + {0}: {1} 条打星/标记记录'
        StatusReadingExif     = '  正在通过 ExifTool 读取星标 ({0}/{1})...'
        NothingAllKept        = '全部 {0} 个候选 RAW 文件均受保护并已保留（打星: {1}, 无法读取: {2}, 纯RAW: {3}），无需清理。'
        NothingFound          = '没有符合条件的 RAW 文件，无需清理。'
        PreviewHeader         = '预览 - 以下 RAW 将被移至回收站（共 {0} 个分组，{1} 个文件）：'
        FlatBucketName        = '（全目录 / 按文件日期模式）'
        FlagNoXmpZero         = '无XMP/0打星'
        FlagNoXmp             = '无XMP'
        FlagKeepRawOnly       = '留纯RAW:{0}'
        FlagDelRawOnly        = '删纯RAW:{0}'
        PreviewLine           = '  {0}   删 {1,4}   留 {2,3}   {3,9}{4}'
        PreviewTotalSize      = '  预计释放空间: {0}'
        PreviewFormats        = '  待删格式分布     : {0}'
        PreviewSidecars       = '  同步清理 XMP 边车: {0} 个'
        PreviewAcrs           = '  同步清理 ACR 缓存: {0} 个'
        PreviewKeptRated      = '  已保留（打星）   : {0} 个（以上分组中 {1} 个，更早历史分组 {2} 个，其中数据库命中 {3} 个）'
        PreviewKeptUnknown    = '  已保留（无法读取）: {0} 个'
        PreviewKeptRawOnly    = '  已保留（纯 RAW）  : {0} 个'
        PreviewSampleHeader   = '  待处理文件预览（显示前 {0} / 共 {1} 个）：'
        PreviewSampleMore     = '    ...（其余 {0} 个已省略，下方输入 V 可查看全部明细）'
        PreviewAllHeader      = '--- 全部文件明细（共 {0} 个）---'
        PreviewAllEnd         = '--- 明细结束 ---'
        ConfirmNote           = '以上仅为预览清单，尚未删除任何文件。'
        ConfirmPrompt         = '输入 Y + 回车 确认移至回收站 | 输入 V 查看全部明细 | 直接回车 = 取消'
        Cancelled             = '已取消，未改动任何文件。（命令行仅预览可加 -DryRun 参数）'
        ProgressActivity      = '正在处理 RAW 文件'
        DoneHeader            = '================ 完成 ================'
        DoneDrySummary        = '预览完成：将清理 {0} 个文件，预计释放 {1}。'
        DoneDryKeptRated      = '已保护并保留 {0} 个打星文件。'
        DoneDryKeptUnknown    = '已保护并保留 {0} 个无法读取的文件。'
        DoneDryKeptRawOnly    = '已保护并保留 {0} 个纯 RAW 文件。'
        DoneDryHint           = '如需真正清理，请去掉 -DryRun 后重新运行并输入 Y 确认。'
        DoneLiveSummary       = '已移至回收站：{0} 个文件，释放空间约 {1}。'
        DoneLiveKeptRated     = '已保留 {0} 个打星文件。'
        DoneLiveKeptUnknown   = '已保留 {0} 个无法读取的文件。'
        DoneLiveKeptRawOnly   = '已保留 {0} 个纯 RAW 文件。'
        DoneFailed            = '失败 {0} 个：'
        DoneLogPath           = '日志文件: {0}'
        JpgBanner             = '===== 将星标同步写入 JPG ====='
        JpgCatalog            = ' 软件图库: {0}'
        JpgDbNone             = '未检测到图库（将直接扫描同目录 RAW / .xmp）'
        JpgSourceLine         = ' 星标来源: {0}'
        JpgSourceAuto         = '自动融合（软件数据库 + 同目录 RAW / .xmp）'
        JpgSourceDbOnly       = '仅软件数据库 (-RatingSource db)'
        JpgSourceFilesOnly    = '仅同目录 RAW / .xmp 文件 (-RatingSource files)'
        JpgRoot               = ' JPG 目录: {0}'
        JpgExifTool           = ' ExifTool: {0}'
        JpgPromptTarget       = '写入方式: [1] 写入 JPG 文件（Win/相册/LR通用；会改字节）  [2] 仅写 .xmp 边车（完全不改 JPG）  （0/回车 = 取消）'
        JpgPromptScope        = '扫描范围: [1] 全部文件夹  [2] 最近 N 天  [3] 单个子文件夹（0 或直接回车 = 取消）'
        JpgPromptRecentDays   = '处理最近多少天（含今天，例如 30；0 或直接回车 = 取消）'
        JpgPromptSubFolder    = '请输入子文件夹名或相对路径（例如 2026-11-22；0 或直接回车 = 取消）'
        ErrNoSubFolder        = '[错误] 找不到子文件夹: {0}'
        ErrInvalidScopeChoice = "[错误] 输入无效 '{0}'，请输入 1、2 或 3。"
        JpgScopeLine          = ' 扫描范围: {0}'
        JpgScopeAll           = '全部文件夹'
        JpgScopeRecent        = '最近 {0} 天（>= {1}）'
        JpgScopeSubFolder     = '子文件夹 {0}'
        JpgModeDry            = ' 运行模式: [预览模式：仅扫描对比，不会修改任何文件]'
        JpgModeLiveJpgBackup  = ' 运行模式: [正式写入 JPG：保留原修改时间 (-P)，原图集中备份到 {0}]'
        JpgModeLiveJpgNoBackup= ' 运行模式: [正式写入 JPG：保留原修改时间 (-P)，原地覆盖 (-NoBackup)]'
        JpgModeLiveSidecar    = ' 运行模式: [正式写入 .xmp 边车：完全不改动 JPG 原文件]'
        JpgReadingCat         = '正在从软件数据库及同目录 RAW/.xmp 读取星标...'
        JpgReadingRawXmp      = '正在通过 ExifTool 检查 {0} 个同名 RAW / .xmp 星标...'
        JpgLoadedCat          = '已加载 {0} 条可匹配当前目录 JPG 的星标记录。'
        JpgNoRatings          = '[提示] 未在数据库或同目录 RAW/.xmp 中找到任何星标记录，无需同步。'
        JpgNoFiles            = '[提示] 在 {0} 下未找到 JPG 文件。'
        JpgFoundFiles         = '共扫描到 {0} 个 JPG 文件。'
        JpgScanningExisting   = '正在通过 ExifTool 检查 {0} 个匹配文件的现有星标...'
        JpgNothingToWrite     = '全部 {0} 个匹配 JPG 均已是目标星标（跳过同星: {1}, 目录无星: {2}），无需修改任何文件。'
        JpgPreviewHeader      = '预览 - 以下 {1} 个文件夹中共有 {0} 个文件将被写入星标：'
        JpgPreviewLine        = '  {0}   新增 {1,4}   更新 {2,3}   同星跳过 {3,4}{4}'
        JpgPreviewFlagConflict= 'XMP冲突跳过:{0}'
        JpgPreviewFlagUnread  = '无法读取跳过:{0}'
        JpgPreviewSkippedDirs = '  + 另有 {0} 个文件夹共 {1} 张匹配 JPG 已有相同星标（自动跳过，不触碰文件）。'
        JpgPreviewTotals      = '  本次写入: {0} 个（新增: {1}, 更新: {2}）   同星跳过: {3} 个   目录无星: {4} 个'
        JpgPreviewExtraSkips  = '  安全跳过: XMP 归属冲突 = {0} 个，无法读取 = {1} 个'
        JpgSampleItem         = '    {0}   ->  {1} 星 [{2}]'
        JpgStatusNew          = '新增'
        JpgStatusUpd          = '更新'
        JpgWarnCloud1         = '[网盘提示] 向 JPG 写入星标会修改文件 EXIF/XMP 字节（文件大小和哈希会变化）。'
        JpgWarnCloud2         = '         网盘可能会重新上传本次实际改动的 {0} 张照片（同星跳过的 {1} 张完全不碰）；原修改时间将自动保留。'
        JpgWarnCloud3         = '         原图备份保存在工具箱 backups\ 目录（不在照片目录留 .jpg_original）；若想完全不触发网盘重传可改用 .xmp 边车模式。'
        JpgWarnSidecar1       = '[说明] 边车模式：不会改动任何 JPG 文件（零 JPG 重传），仅新建/更新同名 .xmp。'
        JpgWarnSidecar2       = '       Lightroom / Bridge 可识别 JPG 的 .xmp 星标，但 Windows 资源管理器和大多数网盘相册通常不读取 .xmp。'
        JpgConfirmNote        = '以上仅为预览清单，尚未修改任何文件。'
        JpgConfirmPrompt      = '输入 Y + 回车 确认写入星标 | 输入 V 查看全部明细 | 直接回车 = 取消'
        JpgCancelled          = '已取消，未修改任何文件。（命令行仅预览可加 -DryRun 参数）'
        JpgBackingUp          = '正在备份 {0} 个原始 JPG 到 {1}...'
        JpgBackupFail         = '[失败] 备份失败（为安全跳过写入）: {0} -> {1}'
        JpgWritingBatch       = '正在写入 {0} 星到 {1} 个 JPG 文件...'
        JpgWritingSidecar     = '正在写入 {0} 星到 {1} 个 .xmp 边车文件...'
        JpgWriteFail          = '[失败] {0} 星批次 ({1}..{2}): {3}'
        JpgWriteOk            = '[成功] 已更新 {0} 个文件 -> {1} 星'
        JpgSummaryHeader      = '================ 汇总 ================'
        JpgSummaryCounts      = '已写入: {0}   同星跳过: {1}   安全跳过: {2}   无星标: {3}   失败: {4}'
        JpgDryDone            = '预览完成，未修改任何文件。'
        JpgDryHint            = '如需正式写入，请去掉 -DryRun 后重新运行并输入 Y 确认。'
        JpgDoneBackupPath     = '原图集中备份目录: {0}'
        JpgDoneNoBackup       = '已原地写入（-NoBackup），并保留了文件原修改时间 (-P)。'
        JpgDoneSidecar        = '已完成 .xmp 边车写入，未改动任何 JPG 原文件。'
        JpgWriteNext          = '后续操作: 如需让 Lightroom 刷新，可选中 JPG 后按 Ctrl+Shift+R 读取元数据。'
        RbBanner              = '===== 一键回滚 JPG 原图备份 ====='
        RbNoBackups           = '[提示] 在 {0} 下没有找到可回滚的 JPG 备份记录。'
        RbListHeader          = '可回滚的备份列表（按时间从新到旧）：'
        RbListItem            = '  [{0}] {1}  （{2} 个文件, {3} -> {4}）'
        RbSelectPrompt        = '请输入要回滚的备份编号（0 或直接回车 = 取消）'
        RbInvalidSel          = "[错误] 无效编号 '{0}'。"
        RbErrNoDir            = '[错误] 找不到备份目录: {0}'
        RbErrNoTargetRoot     = '[错误] 备份目录缺少 manifest.json 且未指定目标目录，请传入 -JpgRoot。'
        RbErrEmpty            = '[提示] 备份目录 {0} 中没有可恢复的 JPG 文件。'
        RbPreviewInfo         = ' 备份目录: {0}'
        RbTargetInfo          = ' 恢复目标: {0}'
        RbFileCount           = ' 文件数量: 将按原字节和原修改时间恢复 {0} 个 JPG 文件（共 {1}）'
        RbConfirmNote         = '该操作会用备份原图覆盖目标目录中对应的 JPG 文件。'
        RbConfirmPrompt       = '输入 Y + 回车 确认无损回滚 | 输入 V 查看全部明细 | 直接回车 = 取消'
        RbCancelled           = '已取消回滚，未修改任何文件。'
        RbDryDone             = '预览完成，未修改任何文件。'
        RbFailItem            = '[失败] {0} -> {1}'
        RbDoneSummary         = '回滚完成：成功恢复 {0} 个文件，失败 {1} 个。'
        RbPromptRemoveBackup  = '回滚已成功。是否删除这份备份目录（{0}）以释放空间？[y/N]（直接回车 = 保留）'
        RbBackupKept          = '原备份目录仍保留于: {0}'
        RbBackupRemoved       = '已清理备份目录: {0}'
        RbCloudTip            = '提示：如网盘上传队列未立即清空，暂停再恢复同步即可重新核对哈希。'
        MenuTitle             = '=========== RAW & JPG 摄影清理与星标工具箱 ==========='
        MenuCurrentRoot       = ' 当前照片目录: {0}'
        MenuCurrentLang       = ' 界面语言    : {0}'
        MenuEnvExifOk         = ' ExifTool    : 已就绪 ({0})'
        MenuEnvExifMissing    = ' ExifTool    : 未找到（请将 exiftool.exe 放入 tools\ 目录）'
        MenuEnvCatOk          = ' LR 目录     : {0}'
        MenuEnvCatLocked      = ' LR 目录     : {0}  [检测到 Lightroom 正在运行!]'
        MenuEnvCatMissing     = ' 软件图库    : 未发现（仍可直接读取 RAW / XMP / JPG 星标）'
        MenuEnvDbFound        = ' 已识别图库  : {0}'
        MenuEnvNoSqlite       = ' [提示] 未检测到 sqlite3.exe 或 Python 3，暂时无法读取桌面软件数据库。'
        MenuOptClean          = '  [1] 清理无星标 RAW 文件（移至回收站）'
        MenuOptRestore        = '  [2] 将星标同步写入 JPG（LR / C1 / 像素蛋糕 / 影像之匠 / XMP）'
        MenuOptRollback       = '  [3] 从 backups\ 一键回滚 JPG 原图备份'
        MenuOptSwitchRoot     = '  [4] 切换目标照片文件夹'
        MenuOptInstallEt      = '  [I] 一键自动下载并配置 ExifTool 到 tools\'
        MenuOptSwitchLang     = '  [L] 切换语言 (中文 / English)'
        MenuOptExit           = '  [0] 退出'
        MenuPrompt            = '请选择功能编号'
        MenuInvalidOpt        = "[提示] 无效选项 '{0}'，请重新输入。"
        MenuPressEnter        = '按回车返回主菜单...'
        MenuSwitchRootPrompt  = '请输入或拖入照片文件夹路径（直接回车保持不变）'
        MenuEtMissingStartup  = '[提示] 尚未检测到 ExifTool（读取和写入照片星标需要它）。'
        MenuEtAutoInstallPrompt = '是否立即自动从官网下载并配置最新版 ExifTool 到 tools\？[Y/n]（直接回车 = 是）'
        EtInstBanner          = '===== 自动下载并配置 ExifTool（官方 64 位版）====='
        EtInstFetchingVer     = '正在从 exiftool.org 获取最新版 ExifTool 下载地址...'
        EtInstDownloading     = '正在下载: {0}'
        EtInstExtracting      = '正在解压并配置到 {0}...'
        EtInstOk              = '[成功] ExifTool {0} 已配置完成: {1}'
        EtInstFail            = '[错误] ExifTool 自动安装失败: {0}'
        EtInstManualHint      = '备选方案：在终端运行 "winget install OliverBetz.ExifTool"，或手动从 https://exiftool.org/ 下载并放入 tools\。'
        EtInstBadZip          = '下载的文件不是有效的 ZIP 压缩包（可能被网络拦截或官网结构变更）。'
        EtInstNoExeInZip      = '压缩包内未找到 exiftool(-k).exe 或 exiftool.exe。'
        MenuBye               = '已退出。'
    }
}

function Resolve-UiLang([string]$Lang) {
    if (-not $Lang -or $Lang -ieq 'auto') {
        $ui = [Globalization.CultureInfo]::CurrentUICulture.Name
        if ($ui -ilike 'zh*') { return 'zh' }
        return 'en'
    }
    if ($Lang -ilike 'zh*') { return 'zh' }
    return 'en'
}

function Set-UiLang([string]$Lang) {
    $script:UiLang = Resolve-UiLang $Lang
}

function Get-ToolkitLocalConfig([string]$ProjectRoot) {
    if (-not $ProjectRoot) { return $null }
    $cfgPath = Join-Path $ProjectRoot 'config.local.json'
    if (-not (Test-Path -LiteralPath $cfgPath -PathType Leaf)) { return $null }
    try {
        $raw = [IO.File]::ReadAllText($cfgPath, [System.Text.Encoding]::UTF8)
        if (-not $raw -or -not $raw.Trim()) { return $null }
        return ($raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Save-ToolkitLocalConfig([string]$ProjectRoot, [string]$LastRoot, [string]$Lang) {
    if (-not $ProjectRoot) { return }
    $cfgPath = Join-Path $ProjectRoot 'config.local.json'
    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $obj = [ordered]@{
            LastRoot = $LastRoot
            Lang     = $Lang
        }
        $json = $obj | ConvertTo-Json
        [IO.File]::WriteAllText($cfgPath, $json, $utf8NoBom)
    } catch {}
}

function T {
    param([string]$Key, [object[]]$FormatArgs)
    $lang = if ($script:UiLang) { $script:UiLang } else { 'en' }
    $dict = $script:LrtMessages[$lang]
    if (-not $dict.ContainsKey($Key)) {
        throw "Missing i18n key '$Key' for language '$lang'"
    }
    $tmpl = $dict[$Key]
    if ($FormatArgs -and $FormatArgs.Count -gt 0) {
        return ($tmpl -f $FormatArgs)
    }
    return $tmpl
}

function Move-ToRecycleBin([string]$Path) {
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
        $Path,
        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
    )
}

function Format-Size([long]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-DefaultRawExtensions {
    return @('.arw', '.cr2', '.cr3', '.nef', '.nrw', '.raf', '.orf', '.rw2', '.dng', '.pef', '.srw')
}

function Get-RawMimeTypes {
    return @{
        '.arw' = @('image/x-sony-arw')
        '.cr2' = @('image/x-canon-cr2')
        '.cr3' = @('image/x-canon-cr3')
        '.nef' = @('image/x-nikon-nef')
        '.nrw' = @('image/x-nikon-nrw', 'image/x-nikon-nef')
        '.raf' = @('image/x-fuji-raf', 'image/x-fujifilm-raf')
        '.orf' = @('image/x-olympus-orf')
        '.rw2' = @('image/x-panasonic-rw2', 'image/x-panasonic-raw')
        '.dng' = @('image/x-adobe-dng')
        '.pef' = @('image/x-pentax-pef')
        '.srw' = @('image/x-samsung-srw')
    }
}

function Normalize-ExtensionList([object]$RawExtensions) {
    $list = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $items = if ($RawExtensions -is [System.Array]) { $RawExtensions } else { @($RawExtensions) }
    foreach ($it in $items) {
        if ($null -eq $it) { continue }
        foreach ($tok in ("$it" -split '[,;\s]+')) {
            $t = $tok.Trim().ToLower()
            if (-not $t) { continue }
            if (-not $t.StartsWith('.')) { $t = '.' + $t }
            if (-not $seen.ContainsKey($t)) {
                $seen[$t] = $true
                $list.Add($t)
            }
        }
    }
    return $list.ToArray()
}

function Try-ParseDatePrefix([string]$FolderName) {
    if (-not $FolderName) { return $null }
    if ($FolderName -notmatch '^(\d{4}-\d{2}-\d{2})(?:$|[\s_\-\.])') { return $null }
    $datePart = $matches[1]
    try {
        $inv = [Globalization.CultureInfo]::InvariantCulture
        return [datetime]::ParseExact($datePart, 'yyyy-MM-dd', $inv).Date
    } catch {
        return $null
    }
}

function Test-HasPhotoRootContent([string]$Dir, [bool]$AllowJpg) {
    if (-not $Dir -or -not (Test-Path -LiteralPath $Dir -PathType Container)) { return $false }
    $subDirs = Get-ChildItem -LiteralPath $Dir -Directory -ErrorAction SilentlyContinue
    foreach ($sd in $subDirs) {
        if ($null -ne (Try-ParseDatePrefix $sd.Name)) { return $true }
    }
    if ($AllowJpg) {
        $hitJpg = Get-ChildItem -LiteralPath $Dir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -ieq '.jpg' -or $_.Extension -ieq '.jpeg' } |
            Select-Object -First 1
        if ($null -ne $hitJpg) { return $true }
    }
    return $false
}

function Resolve-DefaultPhotoRoot([string]$ScriptDir, [bool]$AllowJpg) {
    $baseDir = if ($ScriptDir) { $ScriptDir } else { (Get-Location).Path }
    if (Test-HasPhotoRootContent $baseDir $AllowJpg) { return $baseDir }
    $parent = [IO.Path]::GetDirectoryName($baseDir.TrimEnd('\', '/'))
    if ($parent -and (Test-HasPhotoRootContent $parent $AllowJpg)) { return $parent }
    if ($parent) {
        $grandParent = [IO.Path]::GetDirectoryName($parent.TrimEnd('\', '/'))
        if ($grandParent -and (Test-HasPhotoRootContent $grandParent $AllowJpg)) { return $grandParent }
    }
    return $baseDir
}

function Resolve-ExifToolPath([string]$ExplicitPath, [string]$ProjectRoot, [string]$ScriptDir) {
    if ($ExplicitPath) { return $ExplicitPath }
    $cands = New-Object System.Collections.Generic.List[string]
    if ($ProjectRoot) {
        $cands.Add((Join-Path $ProjectRoot 'tools\exiftool.exe'))
    }
    if ($ScriptDir) {
        $cands.Add((Join-Path $ScriptDir 'exiftool.exe'))
    }
    if ($ProjectRoot) {
        $cands.Add((Join-Path $ProjectRoot 'exiftool.exe'))
        $p = [IO.Path]::GetDirectoryName($ProjectRoot.TrimEnd('\', '/'))
        if ($p) { $cands.Add((Join-Path $p 'exiftool.exe')) }
    }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return $c }
    }
    $cmd = Get-Command exiftool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($ProjectRoot) { return (Join-Path $ProjectRoot 'tools\exiftool.exe') }
    return 'exiftool.exe'
}

function Resolve-CatalogPath([string]$ExplicitPath, [string]$PhotoRoot) {
    if ($ExplicitPath) { return $ExplicitPath }
    $dirs = New-Object System.Collections.Generic.List[string]
    if ($PhotoRoot) {
        $parent = [IO.Path]::GetDirectoryName($PhotoRoot.TrimEnd('\', '/'))
        if ($parent) { $dirs.Add((Join-Path $parent 'Lightroom')) }
    }
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if ($docs) { $dirs.Add((Join-Path $docs 'Lightroom')) }
    $pics = [Environment]::GetFolderPath('MyPictures')
    if ($pics) { $dirs.Add((Join-Path $pics 'Lightroom')) }

    foreach ($d in $dirs) {
        if (-not $d -or -not (Test-Path -LiteralPath $d -PathType Container)) { continue }
        $cats = @(Get-ChildItem -LiteralPath $d -Filter '*.lrcat' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -inotmatch '(Backup|Previews|Sync|Helper|Temporary)' } |
            Sort-Object LastWriteTime -Descending)
        if ($cats.Count -gt 0) {
            return $cats[0].FullName
        }
    }
    return $null
}

function Resolve-CaptureOneCatalogPaths([string]$ExplicitPath, [string]$PhotoRoot) {
    if ($ExplicitPath) {
        if ($ExplicitPath -imatch '\.(cocatalogdb|cosessiondb)$') { return @($ExplicitPath) }
        return @()
    }
    $searchDirs = New-Object System.Collections.Generic.List[string]
    if ($PhotoRoot -and (Test-Path -LiteralPath $PhotoRoot -PathType Container)) {
        $searchDirs.Add($PhotoRoot)
        $parent = [IO.Path]::GetDirectoryName($PhotoRoot.TrimEnd('\', '/'))
        if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
            foreach ($d in (Get-ChildItem -LiteralPath $parent -Directory -Filter 'Capture One*' -ErrorAction SilentlyContinue)) {
                $searchDirs.Add($d.FullName)
            }
        }
    }
    foreach ($special in @([Environment]::GetFolderPath('MyDocuments'), [Environment]::GetFolderPath('MyPictures'))) {
        if ($special -and (Test-Path -LiteralPath $special -PathType Container)) {
            foreach ($d in (Get-ChildItem -LiteralPath $special -Directory -Filter 'Capture One*' -ErrorAction SilentlyContinue)) {
                $searchDirs.Add($d.FullName)
            }
        }
    }

    $found = New-Object System.Collections.Generic.List[object]
    $seen  = @{}
    foreach ($sd in $searchDirs) {
        if (-not $sd -or -not (Test-Path -LiteralPath $sd -PathType Container)) { continue }
        $items = @(Get-ChildItem -LiteralPath $sd -Depth 2 -File -ErrorAction SilentlyContinue | Where-Object {
            ($_.Extension -ieq '.cocatalogdb' -or $_.Extension -ieq '.cosessiondb') -and
            ($_.Name -inotmatch '(Backup|Previews)') -and
            ($_.DirectoryName -inotmatch 'Backup')
        })
        foreach ($it in $items) {
            $k = $it.FullName.ToLower()
            if (-not $seen.ContainsKey($k)) {
                $seen[$k] = $true
                $found.Add($it)
            }
        }
    }
    $sorted = @($found | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { $_.FullName })
    return $sorted
}

function Resolve-PixCakeDbPaths([string]$PixCakeDbRoot) {
    if ($PixCakeDbRoot -ieq 'NONE') { return @() }
    $roots = New-Object System.Collections.Generic.List[string]
    if ($PixCakeDbRoot) {
        $roots.Add($PixCakeDbRoot)
    } else {
        $appData = [Environment]::GetFolderPath('ApplicationData')
        if ($appData) {
            foreach ($sub in @('PixCake-qt_pro\db', 'PixCake-qt\db', 'PixCake\db')) {
                $roots.Add((Join-Path $appData $sub))
            }
        }
        $localApp = [Environment]::GetFolderPath('LocalApplicationData')
        if ($localApp) {
            $roots.Add((Join-Path $localApp 'PixCake-qt_pro\db'))
        }
    }
    $found = New-Object System.Collections.Generic.List[object]
    $seen  = @{}
    foreach ($r in $roots) {
        if (-not $r -or -not (Test-Path -LiteralPath $r -PathType Container)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $r -Filter 'project.db' -Recurse -File -ErrorAction SilentlyContinue)) {
            $k = $f.FullName.ToLower()
            if (-not $seen.ContainsKey($k)) {
                $seen[$k] = $true
                $found.Add($f)
            }
        }
    }
    $dbs = @($found | Sort-Object LastWriteTime -Descending | ForEach-Object { $_.FullName })
    return $dbs
}

function Resolve-PixPrettyDbPaths([string]$PixPrettyDbRoot) {
    if ($PixPrettyDbRoot -ieq 'NONE') { return @() }
    $roots = New-Object System.Collections.Generic.List[string]
    if ($PixPrettyDbRoot) {
        $roots.Add($PixPrettyDbRoot)
    } else {
        $localApp = [Environment]::GetFolderPath('LocalApplicationData')
        if ($localApp) { $roots.Add((Join-Path $localApp 'YanYu Software\PixPretty\config')) }
        $appData = [Environment]::GetFolderPath('ApplicationData')
        if ($appData) { $roots.Add((Join-Path $appData 'YanYu Software\PixPretty\config')) }
    }
    $found = New-Object System.Collections.Generic.List[object]
    $seen  = @{}
    foreach ($r in $roots) {
        if (-not $r -or -not (Test-Path -LiteralPath $r -PathType Container)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $r -Filter 'projects*.db' -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            ($_.Name -inotmatch '(-wal|-shm|backup)') -and ($_.DirectoryName -inotmatch 'backup')
        })) {
            $k = $f.FullName.ToLower()
            if (-not $seen.ContainsKey($k)) {
                $seen[$k] = $true
                $found.Add($f)
            }
        }
    }
    $dbs = @($found | Sort-Object LastWriteTime -Descending | ForEach-Object { $_.FullName })
    return $dbs
}

function Resolve-LuminarCatalogPaths([string]$ExplicitPath, [string]$PhotoRoot) {
    if ($ExplicitPath) {
        if ($ExplicitPath -imatch '\.luminarneo$') { return @($ExplicitPath) }
        return @()
    }
    $searchDirs = New-Object System.Collections.Generic.List[string]
    if ($PhotoRoot -and (Test-Path -LiteralPath $PhotoRoot -PathType Container)) {
        $searchDirs.Add($PhotoRoot)
        $parent = [IO.Path]::GetDirectoryName($PhotoRoot.TrimEnd('\', '/'))
        if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
            $searchDirs.Add($parent)
            foreach ($d in (Get-ChildItem -LiteralPath $parent -Directory -Filter 'Luminar Neo*' -ErrorAction SilentlyContinue)) {
                $searchDirs.Add($d.FullName)
            }
        }
    }
    foreach ($special in @([Environment]::GetFolderPath('MyDocuments'), [Environment]::GetFolderPath('MyPictures'))) {
        if ($special -and (Test-Path -LiteralPath $special -PathType Container)) {
            foreach ($d in (Get-ChildItem -LiteralPath $special -Directory -Filter 'Luminar Neo*' -ErrorAction SilentlyContinue)) {
                $searchDirs.Add($d.FullName)
            }
        }
    }
    $found = New-Object System.Collections.Generic.List[object]
    $seen  = @{}
    foreach ($sd in $searchDirs) {
        if (-not $sd -or -not (Test-Path -LiteralPath $sd -PathType Container)) { continue }
        $items = @(Get-ChildItem -LiteralPath $sd -Depth 2 -File -Filter '*.luminarneo' -ErrorAction SilentlyContinue | Where-Object {
            ($_.Name -inotmatch '(Backup|Cache)') -and ($_.DirectoryName -inotmatch '(Backup|Cache)')
        })
        foreach ($it in $items) {
            $k = $it.FullName.ToLower()
            if (-not $seen.ContainsKey($k)) {
                $seen[$k] = $true
                $found.Add($it)
            }
        }
    }
    $sorted = @($found | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { $_.FullName })
    return $sorted
}

function Test-SidecarBelongsToRaw([string]$XmpPath, [string]$RawPath, [hashtable]$FolderFilesLower) {
    $t = $null
    try {
        $t = [IO.File]::ReadAllText($XmpPath)
    } catch {
        return $null
    }
    $rawFile    = [IO.Path]::GetFileName($RawPath)
    $rawExt     = [IO.Path]::GetExtension($RawPath).ToLower()
    $rawExtBare = $rawExt.TrimStart('.').ToUpper()
    $mimeMap    = Get-RawMimeTypes
    $allowedMimes = if ($mimeMap.ContainsKey($rawExt)) { $mimeMap[$rawExt] } else { @() }

    $saysRaw = $false
    if ($rawExtBare -and ($t -imatch ('SidecarForExtension="' + [regex]::Escape($rawExtBare) + '"'))) {
        $saysRaw = $true
    }
    if ($t -imatch ('RawFileName="' + [regex]::Escape($rawFile) + '"')) {
        $saysRaw = $true
    }
    foreach ($m in $allowedMimes) {
        if (($t -imatch ('dc:format="' + [regex]::Escape($m) + '"')) -or
            ($t -imatch ('<dc:format>\s*' + [regex]::Escape($m) + '\s*</dc:format>'))) {
            $saysRaw = $true
            break
        }
    }

    $saysOther = $false
    if ($t -imatch 'SidecarForExtension="([^"]+)"' -and $matches[1] -ine $rawExtBare) {
        $saysOther = $true
    }
    if ($t -imatch 'dc:format="([^"]+)"' -and ($allowedMimes -notcontains $matches[1].ToLower())) {
        $saysOther = $true
    }
    if ($t -imatch '<dc:format>([^<]+)</dc:format>' -and ($allowedMimes -notcontains $matches[1].Trim().ToLower())) {
        $saysOther = $true
    }
    if ($t -imatch 'RawFileName="([^"]+)"' -and ($matches[1] -inotmatch ([regex]::Escape($rawExt) + '$'))) {
        $saysOther = $true
    }

    if ($saysOther -and -not $saysRaw) { return $false }
    if ($saysRaw) { return $true }

    # Ambiguous undeclared XMP when a companion image shares the same basename -> keep sidecar.
    $baseLower = [IO.Path]::GetFileNameWithoutExtension($RawPath).ToLower()
    foreach ($ext in @('.jpg', '.jpeg', '.hif', '.heic')) {
        if ($FolderFilesLower.ContainsKey($baseLower + $ext)) { return $false }
    }
    return $true
}

function Test-SidecarBelongsToJpg([string]$XmpPath, [string]$JpgPath, [hashtable]$DirFileSet) {
    $t = $null
    try {
        $t = [IO.File]::ReadAllText($XmpPath)
    } catch {
        return $null
    }
    $jpgFile = [IO.Path]::GetFileName($JpgPath)

    $saysJpg = $false
    if ($t -imatch 'SidecarForExtension="(JPG|JPEG)"') { $saysJpg = $true }
    if ($t -imatch ('RawFileName="' + [regex]::Escape($jpgFile) + '"')) { $saysJpg = $true }
    if (($t -imatch 'dc:format="image/jpeg"') -or ($t -imatch '<dc:format>\s*image/jpeg\s*</dc:format>')) { $saysJpg = $true }

    $saysOther = $false
    if ($t -imatch 'SidecarForExtension="([^"]+)"' -and $matches[1] -notmatch '^(JPG|JPEG)$') { $saysOther = $true }
    if ($t -imatch 'dc:format="([^"]+)"' -and ($matches[1].Trim().ToLower() -ne 'image/jpeg')) { $saysOther = $true }
    if ($t -imatch '<dc:format>([^<]+)</dc:format>' -and ($matches[1].Trim().ToLower() -ne 'image/jpeg')) { $saysOther = $true }
    if ($t -imatch 'RawFileName="([^"]+)"' -and ($matches[1] -inotmatch '\.(jpg|jpeg)$')) { $saysOther = $true }

    if ($saysOther -and -not $saysJpg) { return $false }
    if ($saysJpg) { return $true }

    # Ambiguous undeclared XMP when a companion RAW or HIF/HEIC shares the same basename -> do not overwrite.
    $baseLower = [IO.Path]::GetFileNameWithoutExtension($JpgPath).ToLower()
    foreach ($ext in (Get-DefaultRawExtensions)) {
        if ($DirFileSet.ContainsKey($baseLower + $ext)) { return $false }
    }
    foreach ($ext in @('.hif', '.heic')) {
        if ($DirFileSet.ContainsKey($baseLower + $ext)) { return $false }
    }
    return $true
}

function Find-RawSidecars([string]$RawPath, [hashtable]$FolderFilesLower) {
    $dir  = [IO.Path]::GetDirectoryName($RawPath)
    $base = [IO.Path]::GetFileNameWithoutExtension($RawPath)
    $name = [IO.Path]::GetFileName($RawPath)
    $cands = @(
        (Join-Path $dir ($base + '.xmp')),
        (Join-Path $dir ($name + '.xmp'))
    )
    $delList  = New-Object System.Collections.Generic.List[string]
    $readList = New-Object System.Collections.Generic.List[string]
    $hasError = $false
    foreach ($c in $cands) {
        if (Test-Path -LiteralPath $c -PathType Leaf) {
            $readList.Add($c)
            $belongs = Test-SidecarBelongsToRaw -XmpPath $c -RawPath $RawPath -FolderFilesLower $FolderFilesLower
            if ($null -eq $belongs) {
                $hasError = $true
            } elseif ($belongs) {
                $delList.Add($c)
            }
        }
    }
    return [pscustomobject]@{
        DeleteSidecars = $delList.ToArray()
        ReadSidecars   = $readList.ToArray()
        HasError       = $hasError
    }
}

# Fail-safe priority: confirmed rated (>= 1) > unreadable (-1) > confirmed unrated (0)
function Merge-Rating($Current, [int]$NewVal) {
    if ($null -eq $Current) { return $NewVal }
    $cur = [int]$Current
    if ($cur -ge 1 -or $NewVal -ge 1) { return [Math]::Max($cur, $NewVal) }
    if ($cur -eq -1 -or $NewVal -eq -1) { return -1 }
    return 0
}

function Get-ExifToolRatingFromObject($Obj) {
    if ($null -eq $Obj) { return -1 }
    if ($Obj.Error -or $Obj.'ExifTool:Error') { return -1 }
    if (-not ($Obj.FileType -or $Obj.'File:FileType')) { return -1 }
    $best = 0
    foreach ($prop in $Obj.PSObject.Properties) {
        $pname = $prop.Name
        if ($pname -notmatch '(^|:)(Rating|StarRating|RatingPercent|Pick|PickLabel)$') { continue }
        $vals = if ($prop.Value -is [System.Array]) { $prop.Value } else { @($prop.Value) }
        foreach ($v in $vals) {
            if ($null -eq $v) { continue }
            $iv = 0
            if ([int]::TryParse("$v", [ref]$iv)) {
                if ($pname -imatch '(^|:)Pick$') {
                    if ($iv -eq 1 -and $best -lt 1) { $best = 1 }
                } elseif ($pname -imatch '(^|:)PickLabel$') {
                    # digiKam / darktable: 3 = Accepted/Picked (1 = Rejected, 2 = Pending, 0 = None)
                    if ($iv -eq 3 -and $best -lt 1) { $best = 1 }
                } elseif ($pname -imatch '(^|:)RatingPercent$') {
                    $mapped = if ($iv -ge 88) { 5 } elseif ($iv -ge 63) { 4 } elseif ($iv -ge 38) { 3 } elseif ($iv -ge 13) { 2 } elseif ($iv -ge 1) { 1 } else { 0 }
                    if ($mapped -gt $best) { $best = $mapped }
                } else {
                    if ($iv -ge 1 -and $iv -gt $best) { $best = $iv }
                }
            }
        }
    }
    return $best
}

function Get-FileRatingMap {
    param([string[]]$FilePaths, [string]$ExifTool)
    $map = @{}
    if (-not $FilePaths -or $FilePaths.Count -eq 0) { return $map }

    $total = $FilePaths.Count
    $chunk = 2000
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    for ($i = 0; $i -lt $total; $i += $chunk) {
        $n = [Math]::Min($chunk, $total - $i)
        [string[]]$slice = $FilePaths[$i..($i + $n - 1)]
        $argFile = Join-Path $env:TEMP ("lrt_et_file_{0}_{1}.txt" -f $PID, $i)
        $parsed = $null
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            [IO.File]::WriteAllLines($argFile, $slice, $utf8NoBom)
            $json = (& $ExifTool -fast -q -charset filename=UTF8 -json -a -G1 -FileType -Rating -RatingPercent -StarRating -Pick -PickLabel -@ $argFile 2>$null) | Out-String
            if ($LASTEXITCODE -le 1 -and $json) {
                $parsed = $json | ConvertFrom-Json
                if ($parsed -isnot [System.Array]) { $parsed = @($parsed) }
            }
        } catch {
            $parsed = $null
        } finally {
            $ErrorActionPreference = $prevEap
            Remove-Item -LiteralPath $argFile -ErrorAction SilentlyContinue
        }

        $countOk = ($null -ne $parsed -and $parsed.Count -eq $n)
        for ($k = 0; $k -lt $n; $k++) {
            $fp = $slice[$k]
            if (-not $countOk) {
                $map[$fp] = -1
                continue
            }
            $map[$fp] = Get-ExifToolRatingFromObject $parsed[$k]
        }
    }
    return $map
}

function Get-RawRatingMap {
    param([object[]]$Candidates, [string]$ExifTool)
    $map = @{}
    if (-not $Candidates -or $Candidates.Count -eq 0) { return $map }

    $all   = New-Object System.Collections.Generic.List[string]
    $owner = New-Object System.Collections.Generic.List[string]
    foreach ($c in $Candidates) {
        $rawPath = $c.File.FullName
        if ($c.SidecarError) {
            $map[$rawPath] = Merge-Rating $map[$rawPath] -1
        }
        $all.Add($rawPath); $owner.Add($rawPath)
        foreach ($sc in $c.ReadSidecars) {
            $all.Add($sc); $owner.Add($rawPath)
        }
        foreach ($comp in $c.CompanionImages) {
            $all.Add($comp); $owner.Add($rawPath)
        }
    }

    $total = $all.Count
    $chunk = 2000
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    for ($i = 0; $i -lt $total; $i += $chunk) {
        $n = [Math]::Min($chunk, $total - $i)
        [string[]]$slice = $all.GetRange($i, $n).ToArray()
        Write-Host (T 'StatusReadingExif' @([Math]::Min($i + $chunk, $total), $total)) -ForegroundColor DarkGray
        $argFile = Join-Path $env:TEMP ("lrt_et_args_{0}_{1}.txt" -f $PID, $i)
        $parsed = $null
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            [IO.File]::WriteAllLines($argFile, $slice, $utf8NoBom)
            $json = (& $ExifTool -fast -q -charset filename=UTF8 -json -a -G1 -FileType -Rating -RatingPercent -StarRating -Pick -PickLabel -@ $argFile 2>$null) | Out-String
            if ($LASTEXITCODE -le 1 -and $json) {
                $parsed = $json | ConvertFrom-Json
                if ($parsed -isnot [System.Array]) { $parsed = @($parsed) }
            }
        } catch {
            $parsed = $null
        } finally {
            $ErrorActionPreference = $prevEap
            Remove-Item -LiteralPath $argFile -ErrorAction SilentlyContinue
        }

        $countOk = ($null -ne $parsed -and $parsed.Count -eq $n)
        for ($k = 0; $k -lt $n; $k++) {
            $rawPath = $owner[$i + $k]
            if (-not $countOk) {
                $map[$rawPath] = Merge-Rating $map[$rawPath] -1
                continue
            }
            $r = Get-ExifToolRatingFromObject $parsed[$k]
            $map[$rawPath] = Merge-Rating $map[$rawPath] $r
        }
    }
    return $map
}

function Resolve-SqliteCliPath([string]$ProjectRoot, [string]$ScriptDir) {
    $cands = New-Object System.Collections.Generic.List[string]
    if ($ProjectRoot) { $cands.Add((Join-Path $ProjectRoot 'tools\sqlite3.exe')) }
    if ($ScriptDir)   { $cands.Add((Join-Path $ScriptDir 'sqlite3.exe')) }
    if ($ProjectRoot) { $cands.Add((Join-Path $ProjectRoot 'sqlite3.exe')) }
    foreach ($c in $cands) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return $c }
    }
    $cmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Resolve-PythonCliPath {
    foreach ($name in @('python', 'python3')) {
        $cmds = @(Get-Command $name -All -ErrorAction SilentlyContinue)
        foreach ($c in $cmds) {
            $src = $c.Source
            if ($src -and $src.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase) -and ($src -notlike '*\Microsoft\WindowsApps\*') -and (Test-Path -LiteralPath $src -PathType Leaf)) {
                return $src
            }
        }
    }
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $exe = ((& $pyLauncher.Source -3 -c 'import sys; print(sys.executable)' 2>$null) | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $exe -and $exe.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
                return $exe
            }
        } catch {} finally {
            $ErrorActionPreference = $prevEap
        }
    }
    $pyenvCmd = Get-Command pyenv -ErrorAction SilentlyContinue
    if ($pyenvCmd) {
        $prevEap = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $exe = ((& $pyenvCmd.Source which python 2>$null) | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
                return $exe
            }
        } catch {} finally {
            $ErrorActionPreference = $prevEap
        }
    }
    foreach ($name in @('python', 'python3')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd -and ($cmd.Source -notlike '*\Microsoft\WindowsApps\*')) { return $cmd.Source }
    }
    return $null
}

function Get-CatalogRatingMap {
    param(
        [string]$CatPath,
        [string[]]$ExtensionFilter,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $map = @{}
    $sqliteExe = Resolve-SqliteCliPath -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
    $pyExe = $null
    if (-not $sqliteExe) {
        $pyExe = Resolve-PythonCliPath
        if (-not $pyExe) {
            throw (T 'ErrNoSqliteReader' @($CatPath))
        }
    }

    $extWhere = ''
    if ($ExtensionFilter -and $ExtensionFilter.Count -gt 0) {
        $cleanExts = @($ExtensionFilter | ForEach-Object { "'" + $_.TrimStart('.').ToLower().Replace("'", "''") + "'" })
        $extWhere = ' AND LOWER(f.extension) IN (' + ($cleanExts -join ',') + ')'
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tmpScript = Join-Path $env:TEMP ("lrt_cat_q_{0}" -f $PID)
    $tmpOut    = Join-Path $env:TEMP ("lrt_cat_o_{0}.txt" -f $PID)
    $prevEap   = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        if ($sqliteExe) {
            $tmpSql = $tmpScript + '.sql'
            $outSlash = $tmpOut.Replace('\', '/')
            $sql = @"
.timeout 5000
.mode list
.separator |
.output $outSlash
SELECT REPLACE(RTRIM(rf.absolutePath, '/\') || '/' || TRIM(fld.pathFromRoot, '/\'), '\', '/'),
       LOWER(f.baseName),
       MAX(CAST(COALESCE(img.rating, 0) AS INTEGER)),
       MAX(CASE WHEN CAST(COALESCE(img.pick, 0) AS INTEGER) = 1 THEN 1 ELSE 0 END)
FROM Adobe_images img
JOIN AgLibraryFile f ON img.rootFile = f.id_local
JOIN AgLibraryFolder fld ON f.folder = fld.id_local
JOIN AgLibraryRootFolder rf ON fld.rootFolder = rf.id_local
WHERE (COALESCE(img.rating, 0) >= 1 OR COALESCE(img.pick, 0) = 1)$extWhere
GROUP BY rf.absolutePath, fld.pathFromRoot, LOWER(f.baseName);
.output stdout
"@
            [IO.File]::WriteAllText($tmpSql, $sql, $utf8NoBom)
            $errOut = (& $sqliteExe -readonly $CatPath ".read $($tmpSql.Replace('\', '/'))" 2>&1) | Out-String
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmpOut)) {
                throw (T 'ErrCatalogRead' @($LASTEXITCODE, $errOut))
            }
        } else {
            $tmpPy = $tmpScript + '.py'
            [string[]]$pyLines = @(
                "import os, sqlite3, sys",
                "cat = sys.argv[1]",
                "outp = sys.argv[2]",
                "uri = 'file:' + cat.replace('\\', '/')",
                "con = sqlite3.connect(uri + '?mode=ro', uri=True, timeout=5.0)",
                "cur = con.cursor()",
                "q = '''SELECT rf.absolutePath, fld.pathFromRoot, f.baseName,",
                "       MAX(CAST(COALESCE(img.rating, 0) AS INTEGER)),",
                "       MAX(CASE WHEN CAST(COALESCE(img.pick, 0) AS INTEGER) = 1 THEN 1 ELSE 0 END)",
                "       FROM Adobe_images img",
                "       JOIN AgLibraryFile f ON img.rootFile = f.id_local",
                "       JOIN AgLibraryFolder fld ON f.folder = fld.id_local",
                "       JOIN AgLibraryRootFolder rf ON fld.rootFolder = rf.id_local",
                "       WHERE (COALESCE(img.rating, 0) >= 1 OR COALESCE(img.pick, 0) = 1)$extWhere",
                "       GROUP BY rf.absolutePath, fld.pathFromRoot, LOWER(f.baseName)'''",
                "rows = []",
                "for absp, pfr, bn, rt, pk in cur.execute(q):",
                "    fd = os.path.normpath(os.path.join(absp, pfr)).rstrip('\\\\/').lower()",
                "    rows.append(fd + '|' + bn.lower() + '|' + str(rt) + '|' + str(pk))",
                "con.close()",
                "with open(outp, 'w', encoding='utf-8') as fh:",
                "    fh.write('\n'.join(rows))"
            )
            [IO.File]::WriteAllLines($tmpPy, $pyLines, $utf8NoBom)
            $errOut = (& $pyExe $tmpPy $CatPath $tmpOut 2>&1) | Out-String
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmpOut)) {
                throw (T 'ErrCatalogRead' @($LASTEXITCODE, $errOut))
            }
        }

        $lines = [IO.File]::ReadAllLines($tmpOut, [System.Text.Encoding]::UTF8)
        foreach ($line in $lines) {
            if (-not $line) { continue }
            $parts = $line.Split('|')
            if ($parts.Length -ge 4) {
                $normDir = $parts[0].Trim()
                try { $normDir = [IO.Path]::GetFullPath($normDir) } catch {}
                $key = $normDir.TrimEnd('\', '/').ToLower() + '|' + $parts[1].Trim().ToLower()
                $rt = 0; $pk = 0
                [void][int]::TryParse($parts[2], [ref]$rt)
                [void][int]::TryParse($parts[3], [ref]$pk)
                $eff = if ($rt -ge 1) { $rt } elseif ($pk -eq 1) { 1 } else { 0 }
                if ($eff -ge 1) {
                    $map[$key] = Merge-Rating $map[$key] $eff
                }
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
        Remove-Item -LiteralPath ($tmpScript + '.sql') -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath ($tmpScript + '.py')  -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOut               -ErrorAction SilentlyContinue
    }
    return $map
}

function Get-CaptureOneRatingMap {
    param(
        [string]$CatPath,
        [string[]]$ExtensionFilter,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $map = @{}
    if (-not $CatPath -or -not (Test-Path -LiteralPath $CatPath -PathType Leaf)) { return $map }

    $sqliteExe = Resolve-SqliteCliPath -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
    $pyExe = $null
    if (-not $sqliteExe) {
        $pyExe = Resolve-PythonCliPath
        if (-not $pyExe) {
            throw (T 'ErrNoSqliteReader' @($CatPath))
        }
    }

    $extSet = $null
    if ($ExtensionFilter -and $ExtensionFilter.Count -gt 0) {
        $extSet = @{}
        foreach ($e in $ExtensionFilter) { $extSet[$e.TrimStart('.').ToLower()] = $true }
    }

    $catDir = [IO.Path]::GetDirectoryName($CatPath)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tmpScript = Join-Path $env:TEMP ("lrt_c1_q_{0}" -f $PID)
    $tmpOut    = Join-Path $env:TEMP ("lrt_c1_o_{0}.txt" -f $PID)
    $prevEap   = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        if ($sqliteExe) {
            $tmpSql = $tmpScript + '.sql'
            $outSlash = $tmpOut.Replace('\', '/')
            $sql = @"
.timeout 5000
.mode list
.separator |
.output $outSlash
SELECT COALESCE(p.ZWINROOT, ''), COALESCE(p.ZRELATIVEPATH, ''), i.ZIMAGEFILENAME,
       MAX(CAST(COALESCE(m.ZBASIC_RATING, 0) AS INTEGER))
FROM ZVARIANTMETADATA m
JOIN ZVARIANTLAYER l ON m.ZLAYER = l.Z_PK
JOIN ZVARIANT v ON l.ZVARIANT = v.Z_PK
JOIN ZIMAGE i ON v.ZIMAGE = i.Z_PK
JOIN ZPATHLOCATION p ON i.ZIMAGELOCATION = p.Z_PK
WHERE COALESCE(m.ZBASIC_RATING, 0) >= 1
  AND COALESCE(i.ZISTRASHED, 0) = 0
GROUP BY p.Z_PK, LOWER(i.ZIMAGEFILENAME);
.output stdout
"@
            [IO.File]::WriteAllText($tmpSql, $sql, $utf8NoBom)
            $errOut = (& $sqliteExe -readonly $CatPath ".read $($tmpSql.Replace('\', '/'))" 2>&1) | Out-String
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmpOut)) {
                throw (T 'ErrCatalogRead' @($LASTEXITCODE, $errOut))
            }
        } else {
            $tmpPy = $tmpScript + '.py'
            [string[]]$pyLines = @(
                "import os, sqlite3, sys",
                "cat = sys.argv[1]",
                "outp = sys.argv[2]",
                "cat_dir = sys.argv[3]",
                "uri = 'file:' + cat.replace('\\', '/')",
                "con = sqlite3.connect(uri + '?mode=ro', uri=True, timeout=5.0)",
                "cur = con.cursor()",
                "q = '''SELECT COALESCE(p.ZWINROOT, ''), COALESCE(p.ZRELATIVEPATH, ''), i.ZIMAGEFILENAME,",
                "       MAX(CAST(COALESCE(m.ZBASIC_RATING, 0) AS INTEGER))",
                "       FROM ZVARIANTMETADATA m",
                "       JOIN ZVARIANTLAYER l ON m.ZLAYER = l.Z_PK",
                "       JOIN ZVARIANT v ON l.ZVARIANT = v.Z_PK",
                "       JOIN ZIMAGE i ON v.ZIMAGE = i.Z_PK",
                "       JOIN ZPATHLOCATION p ON i.ZIMAGELOCATION = p.Z_PK",
                "       WHERE COALESCE(m.ZBASIC_RATING, 0) >= 1",
                "         AND COALESCE(i.ZISTRASHED, 0) = 0",
                "       GROUP BY p.Z_PK, LOWER(i.ZIMAGEFILENAME)'''",
                "rows = []",
                "for winroot, relp, fn, rt in cur.execute(q):",
                "    base_root = winroot.strip() if winroot and winroot.strip() else cat_dir",
                "    rel_clean = (relp or '').strip().lstrip('\\\\/')",
                "    fd = os.path.normpath(os.path.join(base_root, rel_clean)).rstrip('\\\\/').lower()",
                "    rows.append(fd + '|' + fn + '|' + str(rt))",
                "con.close()",
                "with open(outp, 'w', encoding='utf-8') as fh:",
                "    fh.write('\n'.join(rows))"
            )
            [IO.File]::WriteAllLines($tmpPy, $pyLines, $utf8NoBom)
            $errOut = (& $pyExe $tmpPy $CatPath $tmpOut $catDir 2>&1) | Out-String
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmpOut)) {
                throw (T 'ErrCatalogRead' @($LASTEXITCODE, $errOut))
            }
        }

        $lines = [IO.File]::ReadAllLines($tmpOut, [System.Text.Encoding]::UTF8)
        foreach ($line in $lines) {
            if (-not $line) { continue }
            $parts = $line.Split('|')
            $dirPart = ''
            $fnPart  = ''
            $rtPart  = ''
            if ($parts.Length -eq 4 -and $sqliteExe) {
                $baseRoot = if ($parts[0].Trim()) { $parts[0].Trim() } else { $catDir }
                $relClean = $parts[1].Trim().TrimStart('\', '/')
                $dirPart = if ($relClean) { Join-Path $baseRoot $relClean } else { $baseRoot }
                $fnPart  = $parts[2].Trim()
                $rtPart  = $parts[3].Trim()
            } elseif ($parts.Length -ge 3) {
                $dirPart = $parts[0].Trim()
                $fnPart  = $parts[1].Trim()
                $rtPart  = $parts[2].Trim()
            } else { continue }

            if (-not $fnPart) { continue }
            $extBare = [IO.Path]::GetExtension($fnPart).TrimStart('.').ToLower()
            if ($extSet -and -not $extSet.ContainsKey($extBare)) { continue }
            try { $dirPart = [IO.Path]::GetFullPath($dirPart) } catch {}
            $baseLower = [IO.Path]::GetFileNameWithoutExtension($fnPart).ToLower()
            $key = $dirPart.TrimEnd('\', '/').ToLower() + '|' + $baseLower
            $rt = 0
            [void][int]::TryParse($rtPart, [ref]$rt)
            if ($rt -ge 1) {
                $map[$key] = Merge-Rating $map[$key] $rt
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
        Remove-Item -LiteralPath ($tmpScript + '.sql') -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath ($tmpScript + '.py')  -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOut               -ErrorAction SilentlyContinue
    }
    return $map
}

function Get-PixCakeRatingMap {
    param(
        [string[]]$DbPaths,
        [string[]]$ExtensionFilter,
        [string]$ScopeRoot,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $map = @{}
    if (-not $DbPaths -or $DbPaths.Count -eq 0) { return $map }

    $pyExe = Resolve-PythonCliPath
    $sqliteExe = if (-not $pyExe) { Resolve-SqliteCliPath -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir } else { $null }
    if (-not $pyExe -and -not $sqliteExe) { return $map }

    $extSet = $null
    if ($ExtensionFilter -and $ExtensionFilter.Count -gt 0) {
        $extSet = @{}
        foreach ($e in $ExtensionFilter) { $extSet[$e.TrimStart('.').ToLower()] = $true }
    }
    $scopeNorm = if ($ScopeRoot) { $ScopeRoot.TrimEnd('\', '/').ToLower() } else { '' }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tmpDbList = Join-Path $env:TEMP ("lrt_px_list_{0}.txt" -f $PID)
    $tmpPy     = Join-Path $env:TEMP ("lrt_px_q_{0}.py" -f $PID)
    $tmpOut    = Join-Path $env:TEMP ("lrt_px_o_{0}.txt" -f $PID)
    $prevEap   = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        if ($pyExe) {
            [IO.File]::WriteAllLines($tmpDbList, [string[]]$DbPaths, $utf8NoBom)
            [string[]]$pyLines = @(
                "import os, sqlite3, sys",
                "dblist, outp = sys.argv[1], sys.argv[2]",
                "rows = []",
                "q = '''SELECT originalImagePath, MAX(CAST(COALESCE(starLevel,0) AS INTEGER)),",
                "       MAX(CASE WHEN COALESCE(selectFlag,0)=1 OR COALESCE(isFavourite,0)=1 THEN 1 ELSE 0 END)",
                "       FROM thumbnail",
                "       WHERE COALESCE(inRecycleBin,0)=0 AND originalImagePath IS NOT NULL AND originalImagePath<>''",
                "         AND (COALESCE(starLevel,0)>=1 OR COALESCE(selectFlag,0)=1 OR COALESCE(isFavourite,0)=1)",
                "       GROUP BY originalImagePath'''",
                "with open(dblist, 'r', encoding='utf-8') as f:",
                "    paths = [ln.strip() for ln in f if ln.strip()]",
                "for dbp in paths:",
                "    try:",
                "        uri = 'file:' + dbp.replace('\\', '/')",
                "        con = sqlite3.connect(uri + '?mode=ro', uri=True, timeout=3.0)",
                "        cur = con.cursor()",
                "        for imgp, st, fl in cur.execute(q):",
                "            rows.append(imgp + '|' + str(st) + '|' + str(fl))",
                "        con.close()",
                "    except Exception:",
                "        pass",
                "with open(outp, 'w', encoding='utf-8') as fh:",
                "    fh.write('\n'.join(rows))"
            )
            [IO.File]::WriteAllLines($tmpPy, $pyLines, $utf8NoBom)
            $null = (& $pyExe $tmpPy $tmpDbList $tmpOut 2>&1)
            if (Test-Path -LiteralPath $tmpOut) {
                $lines = [IO.File]::ReadAllLines($tmpOut, [System.Text.Encoding]::UTF8)
                foreach ($line in $lines) {
                    if (-not $line) { continue }
                    $parts = $line.Split('|')
                    if ($parts.Length -lt 3) { continue }
                    $imgPath = $parts[0].Trim()
                    $dirPart = [IO.Path]::GetDirectoryName($imgPath)
                    if (-not $dirPart) { continue }
                    try { $dirPart = [IO.Path]::GetFullPath($dirPart) } catch {}
                    $dirLower = $dirPart.TrimEnd('\', '/').ToLower()
                    if ($scopeNorm -and -not ($dirLower -eq $scopeNorm -or $dirLower.StartsWith($scopeNorm + '\'))) { continue }
                    $extBare = [IO.Path]::GetExtension($imgPath).TrimStart('.').ToLower()
                    if ($extSet -and -not $extSet.ContainsKey($extBare)) { continue }
                    $baseLower = [IO.Path]::GetFileNameWithoutExtension($imgPath).ToLower()
                    $st = 0; $fl = 0
                    [void][int]::TryParse($parts[1], [ref]$st)
                    [void][int]::TryParse($parts[2], [ref]$fl)
                    $eff = if ($st -ge 1) { $st } elseif ($fl -eq 1) { 1 } else { 0 }
                    if ($eff -ge 1) {
                        $key = $dirLower + '|' + $baseLower
                        $map[$key] = Merge-Rating $map[$key] $eff
                    }
                }
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
        Remove-Item -LiteralPath $tmpDbList -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpPy     -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOut    -ErrorAction SilentlyContinue
    }
    return $map
}

function Get-PixPrettyRatingMap {
    param(
        [string[]]$DbPaths,
        [string[]]$ExtensionFilter,
        [string]$ScopeRoot,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $map = @{}
    if (-not $DbPaths -or $DbPaths.Count -eq 0) { return $map }

    $pyExe = Resolve-PythonCliPath
    if (-not $pyExe) { return $map }

    $extSet = $null
    if ($ExtensionFilter -and $ExtensionFilter.Count -gt 0) {
        $extSet = @{}
        foreach ($e in $ExtensionFilter) { $extSet[$e.TrimStart('.').ToLower()] = $true }
    }
    $scopeNorm = if ($ScopeRoot) { $ScopeRoot.TrimEnd('\', '/').ToLower() } else { '' }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tmpDbList = Join-Path $env:TEMP ("lrt_pp_list_{0}.txt" -f $PID)
    $tmpPy     = Join-Path $env:TEMP ("lrt_pp_q_{0}.py" -f $PID)
    $tmpOut    = Join-Path $env:TEMP ("lrt_pp_o_{0}.txt" -f $PID)
    $prevEap   = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        [IO.File]::WriteAllLines($tmpDbList, [string[]]$DbPaths, $utf8NoBom)
        [string[]]$pyLines = @(
            "import ctypes, os, re, sqlite3, string, sys",
            "dblist, outp = sys.argv[1], sys.argv[2]",
            "guid_to_drive = {}",
            "try:",
            "    k32 = ctypes.windll.kernel32",
            "    mask = k32.GetLogicalDrives()",
            "    buf = ctypes.create_unicode_buffer(128)",
            "    for idx, ch in enumerate(string.ascii_uppercase):",
            "        if not (mask & (1 << idx)): continue",
            "        rt = ch + ':\\'",
            "        if k32.GetDriveTypeW(rt) in (2, 3):",
            "            if k32.GetVolumeNameForVolumeMountPointW(rt, buf, 128):",
            "                guid_to_drive[buf.value.rstrip('\\/').lower()] = rt",
            "except Exception:",
            "    pass",
            "q = '''SELECT COALESCE(i.root_path_id,''), COALESCE(i.relative_path,''), COALESCE(i.name,''),",
            "       MAX(CAST(COALESCE(i.level,0) AS INTEGER)),",
            "       MAX(CASE WHEN CAST(COALESCE(i.flag_mark,0) AS INTEGER)=1 THEN 1 ELSE 0 END)",
            "       FROM images i",
            "       LEFT JOIN projects p ON i.project_id = p.project_id",
            "       WHERE COALESCE(i.is_del,0)=0 AND COALESCE(p.del_states,0)=0",
            "         AND (COALESCE(i.level,0)>=1 OR COALESCE(i.flag_mark,0)=1)",
            "       GROUP BY i.root_path_id, i.relative_path, i.name'''",
            "rows = []",
            "with open(dblist, 'r', encoding='utf-8') as f:",
            "    paths = [ln.strip() for ln in f if ln.strip()]",
            "for dbp in paths:",
            "    try:",
            "        uri = 'file:' + dbp.replace('\\', '/')",
            "        con = sqlite3.connect(uri + '?mode=ro', uri=True, timeout=3.0)",
            "        cur = con.cursor()",
            "        for rid, relp, fn, lv, fl in cur.execute(q):",
            "            rkey = rid.strip().rstrip('\\/').lower()",
            "            rel_clean = relp.strip().replace('/', '\\')",
            "            fullp = ''",
            "            if rkey in guid_to_drive:",
            "                drv = guid_to_drive[rkey]",
            "                fullp = os.path.normpath(os.path.join(drv, rel_clean.lstrip('\\/')))",
            "            elif re.match(r'^[a-zA-Z]:([\\/]|$)', rid.strip()):",
            "                drv = rid.strip()[:2] + '\\'",
            "                fullp = os.path.normpath(os.path.join(drv, rel_clean.lstrip('\\/')))",
            "            elif re.match(r'^[a-zA-Z]:[\\/]', rel_clean):",
            "                fullp = os.path.normpath(rel_clean)",
            "            if not fullp: continue",
            "            if fn and os.path.basename(fullp).lower() != fn.strip().lower():",
            "                fullp = os.path.join(fullp, fn.strip())",
            "            rows.append(fullp + '|' + str(lv) + '|' + str(fl))",
            "        con.close()",
            "    except Exception:",
            "        pass",
            "with open(outp, 'w', encoding='utf-8') as fh:",
            "    fh.write('\n'.join(rows))"
        )
        [IO.File]::WriteAllLines($tmpPy, $pyLines, $utf8NoBom)
        $null = (& $pyExe $tmpPy $tmpDbList $tmpOut 2>&1)
        if (Test-Path -LiteralPath $tmpOut) {
            $lines = [IO.File]::ReadAllLines($tmpOut, [System.Text.Encoding]::UTF8)
            foreach ($line in $lines) {
                if (-not $line) { continue }
                $parts = $line.Split('|')
                if ($parts.Length -lt 3) { continue }
                $imgPath = $parts[0].Trim()
                $dirPart = [IO.Path]::GetDirectoryName($imgPath)
                if (-not $dirPart) { continue }
                try { $dirPart = [IO.Path]::GetFullPath($dirPart) } catch {}
                $dirLower = $dirPart.TrimEnd('\', '/').ToLower()
                if ($scopeNorm -and -not ($dirLower -eq $scopeNorm -or $dirLower.StartsWith($scopeNorm + '\'))) { continue }
                $extBare = [IO.Path]::GetExtension($imgPath).TrimStart('.').ToLower()
                if ($extSet -and -not $extSet.ContainsKey($extBare)) { continue }
                $baseLower = [IO.Path]::GetFileNameWithoutExtension($imgPath).ToLower()
                $lv = 0; $fl = 0
                [void][int]::TryParse($parts[1], [ref]$lv)
                [void][int]::TryParse($parts[2], [ref]$fl)
                $eff = if ($lv -ge 1) { $lv } elseif ($fl -eq 1) { 1 } else { 0 }
                if ($eff -ge 1) {
                    $key = $dirLower + '|' + $baseLower
                    $map[$key] = Merge-Rating $map[$key] $eff
                }
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
        Remove-Item -LiteralPath $tmpDbList -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpPy     -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOut    -ErrorAction SilentlyContinue
    }
    return $map
}

function Get-LuminarNeoRatingMap {
    param(
        [string]$CatPath,
        [string[]]$ExtensionFilter,
        [string]$ScopeRoot,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $map = @{}
    if (-not $CatPath -or -not (Test-Path -LiteralPath $CatPath -PathType Leaf)) { return $map }

    $pyExe = Resolve-PythonCliPath
    if (-not $pyExe) { return $map }

    $extSet = $null
    if ($ExtensionFilter -and $ExtensionFilter.Count -gt 0) {
        $extSet = @{}
        foreach ($e in $ExtensionFilter) { $extSet[$e.TrimStart('.').ToLower()] = $true }
    }
    $scopeNorm = if ($ScopeRoot) { $ScopeRoot.TrimEnd('\', '/').ToLower() } else { '' }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $tmpPy     = Join-Path $env:TEMP ("lrt_lum_q_{0}.py" -f $PID)
    $tmpOut    = Join-Path $env:TEMP ("lrt_lum_o_{0}.txt" -f $PID)
    $prevEap   = $ErrorActionPreference

    try {
        $ErrorActionPreference = 'Continue'
        [string[]]$pyLines = @(
            "import ctypes, json, os, re, sqlite3, string, sys",
            "cat, outp = sys.argv[1], sys.argv[2]",
            "serial_to_drive = {}",
            "try:",
            "    k32 = ctypes.windll.kernel32",
            "    mask = k32.GetLogicalDrives()",
            "    for idx, ch in enumerate(string.ascii_uppercase):",
            "        if not (mask & (1 << idx)): continue",
            "        rt = ch + ':\\'",
            "        if k32.GetDriveTypeW(rt) in (2, 3):",
            "            ser = ctypes.c_ulong(0)",
            "            if k32.GetVolumeInformationW(rt, None, 0, ctypes.byref(ser), None, None, None, 0):",
            "                serial_to_drive[f'{ser.value:08X}'] = rt",
            "except Exception:",
            "    pass",
            "q = '''SELECT COALESCE(v.info_wide_ch,''), COALESCE(v.guid_wide_ch,''),",
            "       COALESCE(p.path_wide_ch,''), i.path_wide_ch,",
            "       MAX(CAST(COALESCE(u.rating,0) AS INTEGER)),",
            "       MAX(CASE WHEN CAST(COALESCE(u.marker,0) AS INTEGER)=1 THEN 1 ELSE 0 END)",
            "       FROM image_user_attributes u",
            "       JOIN images i ON u._out_id_int_64 = i._id_int_64",
            "       JOIN paths_images pi ON pi._val_id_int_64 = i._id_int_64",
            "       JOIN paths p ON pi._key_id_int_64 = p._id_int_64",
            "       LEFT JOIN volumes v ON p.volume_id_int_64 = v._id_int_64",
            "       WHERE COALESCE(u.marked_to_delete_bool,0)=0 AND COALESCE(u.trash_bool,0)=0",
            "         AND COALESCE(i.marked_to_delete_bool,0)=0",
            "         AND (COALESCE(u.rating,0)>=1 OR COALESCE(u.marker,0)=1)",
            "       GROUP BY v._id_int_64, p._id_int_64, LOWER(i.path_wide_ch)'''",
            "rows = []",
            "try:",
            "    uri = 'file:' + cat.replace('\\', '/')",
            "    con = sqlite3.connect(uri + '?mode=ro', uri=True, timeout=3.0)",
            "    cur = con.cursor()",
            "    for vinfo, vguid, ppath, fn, rt, mk in cur.execute(q):",
            "        drv = ''",
            "        if vinfo:",
            "            s_up = vinfo.strip()",
            "            if s_up.startswith('{'):",
            "                try:",
            "                    vsn = str(json.loads(s_up).get('VolumeSerialNumber', '')).strip().upper()",
            "                    if vsn in serial_to_drive: drv = serial_to_drive[vsn]",
            "                except Exception:",
            "                    pass",
            "            elif re.match(r'^[a-zA-Z]:([\\/]|$)', s_up):",
            "                drv = s_up[:2] + '\\'",
            "        if not drv and vguid and re.match(r'^[a-zA-Z]:([\\/]|$)', vguid.strip()):",
            "            drv = vguid.strip()[:2] + '\\'",
            "        pclean = ppath.strip().replace('/', '\\')",
            "        if drv:",
            "            full_dir = os.path.normpath(os.path.join(drv, pclean.lstrip('\\/')))",
            "        elif re.match(r'^[a-zA-Z]:[\\/]', pclean):",
            "            full_dir = os.path.normpath(pclean)",
            "        else:",
            "            continue",
            "        rows.append(full_dir + '|' + fn.strip() + '|' + str(rt) + '|' + str(mk))",
            "    con.close()",
            "except Exception:",
            "    pass",
            "with open(outp, 'w', encoding='utf-8') as fh:",
            "    fh.write('\n'.join(rows))"
        )
        [IO.File]::WriteAllLines($tmpPy, $pyLines, $utf8NoBom)
        $null = (& $pyExe $tmpPy $CatPath $tmpOut 2>&1)
        if (Test-Path -LiteralPath $tmpOut) {
            $lines = [IO.File]::ReadAllLines($tmpOut, [System.Text.Encoding]::UTF8)
            foreach ($line in $lines) {
                if (-not $line) { continue }
                $parts = $line.Split('|')
                if ($parts.Length -lt 4) { continue }
                $dirPart = $parts[0].Trim()
                $fnPart  = $parts[1].Trim()
                if (-not $dirPart -or -not $fnPart) { continue }
                try { $dirPart = [IO.Path]::GetFullPath($dirPart) } catch {}
                $dirLower = $dirPart.TrimEnd('\', '/').ToLower()
                if ($scopeNorm -and -not ($dirLower -eq $scopeNorm -or $dirLower.StartsWith($scopeNorm + '\'))) { continue }
                $extBare = [IO.Path]::GetExtension($fnPart).TrimStart('.').ToLower()
                if ($extSet -and -not $extSet.ContainsKey($extBare)) { continue }
                $baseLower = [IO.Path]::GetFileNameWithoutExtension($fnPart).ToLower()
                $rt = 0; $mk = 0
                [void][int]::TryParse($parts[2], [ref]$rt)
                [void][int]::TryParse($parts[3], [ref]$mk)
                $eff = if ($rt -ge 1) { $rt } elseif ($mk -eq 1) { 1 } else { 0 }
                if ($eff -ge 1) {
                    $key = $dirLower + '|' + $baseLower
                    $map[$key] = Merge-Rating $map[$key] $eff
                }
            }
        }
    } finally {
        $ErrorActionPreference = $prevEap
        Remove-Item -LiteralPath $tmpPy  -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpOut -ErrorAction SilentlyContinue
    }
    return $map
}

function Get-AllSoftwareRatingMap {
    param(
        [string]$PhotoRoot,
        [string]$ExplicitCatalogPath,
        [string]$PixCakeDbRoot,
        [string]$PixPrettyDbRoot,
        [string[]]$ExtensionFilter,
        [string]$ProjectRoot,
        [string]$ScriptDir
    )
    $merged  = @{}
    $labels  = New-Object System.Collections.Generic.List[string]
    $locks   = New-Object System.Collections.Generic.List[string]
    $details = New-Object System.Collections.Generic.List[string]

    if ($ExplicitCatalogPath) {
        if ($ExplicitCatalogPath -imatch '\.(cocatalogdb|cosessiondb)$') {
            $m = Get-CaptureOneRatingMap -CatPath $ExplicitCatalogPath -ExtensionFilter $ExtensionFilter -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
            $lbl = "Capture One ($(Split-Path -Leaf $ExplicitCatalogPath))"
            $labels.Add($lbl)
            $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
        } elseif ($ExplicitCatalogPath -imatch '\.luminarneo$') {
            $m = Get-LuminarNeoRatingMap -CatPath $ExplicitCatalogPath -ExtensionFilter $ExtensionFilter -ScopeRoot $PhotoRoot -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
            $lbl = "Luminar Neo ($(Split-Path -Leaf $ExplicitCatalogPath))"
            $labels.Add($lbl)
            $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
        } else {
            if (Test-Path -LiteralPath ($ExplicitCatalogPath + '.lock')) { $locks.Add($ExplicitCatalogPath) }
            $m = Get-CatalogRatingMap -CatPath $ExplicitCatalogPath -ExtensionFilter $ExtensionFilter -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
            $lbl = "Lightroom ($(Split-Path -Leaf $ExplicitCatalogPath))"
            $labels.Add($lbl)
            $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
        }
    } else {
        $lrCat = Resolve-CatalogPath -ExplicitPath $null -PhotoRoot $PhotoRoot
        if ($lrCat -and (Test-Path -LiteralPath $lrCat -PathType Leaf)) {
            if (Test-Path -LiteralPath ($lrCat + '.lock')) { $locks.Add($lrCat) }
            $m = Get-CatalogRatingMap -CatPath $lrCat -ExtensionFilter $ExtensionFilter -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
            $lbl = "Lightroom ($(Split-Path -Leaf $lrCat))"
            $labels.Add($lbl)
            $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
        }

        $c1Cats = Resolve-CaptureOneCatalogPaths -ExplicitPath $null -PhotoRoot $PhotoRoot
        foreach ($c1 in $c1Cats) {
            if (Test-Path -LiteralPath $c1 -PathType Leaf) {
                $m = Get-CaptureOneRatingMap -CatPath $c1 -ExtensionFilter $ExtensionFilter -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
                foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
                $lbl = "Capture One ($(Split-Path -Leaf $c1))"
                $labels.Add($lbl)
                $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
            }
        }

        $pxDbs = Resolve-PixCakeDbPaths -PixCakeDbRoot $PixCakeDbRoot
        if ($pxDbs.Count -gt 0) {
            $m = Get-PixCakeRatingMap -DbPaths $pxDbs -ExtensionFilter $ExtensionFilter -ScopeRoot $PhotoRoot -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            if ($m.Count -gt 0) {
                foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
                $lbl = "PixCake ($($pxDbs.Count) project DBs)"
                $labels.Add($lbl)
                $details.Add((T 'StatusLoadedDbItem' @('PixCake', $m.Count)))
            }
        }

        $ppDbs = Resolve-PixPrettyDbPaths -PixPrettyDbRoot $PixPrettyDbRoot
        if ($ppDbs.Count -gt 0) {
            $m = Get-PixPrettyRatingMap -DbPaths $ppDbs -ExtensionFilter $ExtensionFilter -ScopeRoot $PhotoRoot -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
            if ($m.Count -gt 0) {
                foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
                $lbl = "PixPretty ($($ppDbs.Count) DB)"
                $labels.Add($lbl)
                $details.Add((T 'StatusLoadedDbItem' @('PixPretty', $m.Count)))
            }
        }

        $lumCats = Resolve-LuminarCatalogPaths -ExplicitPath $null -PhotoRoot $PhotoRoot
        foreach ($lc in $lumCats) {
            if (Test-Path -LiteralPath $lc -PathType Leaf) {
                $m = Get-LuminarNeoRatingMap -CatPath $lc -ExtensionFilter $ExtensionFilter -ScopeRoot $PhotoRoot -ProjectRoot $ProjectRoot -ScriptDir $ScriptDir
                if ($m.Count -gt 0) {
                    foreach ($k in $m.Keys) { $merged[$k] = Merge-Rating $merged[$k] $m[$k] }
                    $lbl = "Luminar Neo ($(Split-Path -Leaf $lc))"
                    $labels.Add($lbl)
                    $details.Add((T 'StatusLoadedDbItem' @($lbl, $m.Count)))
                }
            }
        }
    }

    return [pscustomobject]@{
        Ratings      = $merged
        Labels       = $labels.ToArray()
        LockWarnings = $locks.ToArray()
        Details      = $details.ToArray()
    }
}

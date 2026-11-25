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
        RatingKeep            = 'KEEP star-rated files (RAW + XMP + JPG/HIF + Lightroom)'
        HeaderRawOnly         = ' RAW-only: {0}'
        RawOnlyDelete         = 'DELETE RAW-only files too (-DeleteRawOnly)'
        RawOnlyKeep           = 'KEEP RAW-only files (no companion JPG/HIF)'
        HeaderCatalog         = ' Catalog : {0}'
        CatSkipped            = 'skipped (-DeleteRated)'
        CatDisabled           = 'disabled (-NoCatalog)'
        CatNotFound           = 'not found (ExifTool only)'
        HeaderMode            = ' Mode    : {0}'
        ModeDryRun            = '[DRY-RUN: nothing will be deleted]'
        ModeLive              = '[LIVE: will move to Recycle Bin after confirmation]'
        StatusReadingCatalog  = '  Reading star ratings from Lightroom catalog...'
        StatusLoadedCatalog   = '  Loaded {0} rated/picked entry(ies) from Lightroom catalog.'
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
        PreviewKeptRated      = '  Kept (star-rated)      : {0} (in above groups: {1}, older groups: {2}, LR catalog hits: {3})'
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
        JpgBanner             = '===== Restore Lightroom Star Ratings to JPG ====='
        JpgCatalog            = ' Catalog : {0}'
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
        JpgReadingCat         = 'Extracting ratings from Lightroom catalog...'
        JpgLoadedCat          = 'Loaded {0} folder+name rated/picked entry(ies) from catalog.'
        JpgNoRatings          = '[INFO] No rated entries in catalog. Nothing to restore.'
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
        MenuTitle             = '=========== Lightroom RAW Toolkit ==========='
        MenuCurrentRoot       = ' Photo folder: {0}'
        MenuCurrentLang       = ' Language    : {0}'
        MenuEnvExifOk         = ' ExifTool    : OK ({0})'
        MenuEnvExifMissing    = ' ExifTool    : NOT FOUND (place exiftool.exe in tools\)'
        MenuEnvCatOk          = ' LR Catalog  : {0}'
        MenuEnvCatLocked      = ' LR Catalog  : {0}  [Lightroom is running!]'
        MenuEnvCatMissing     = ' LR Catalog  : not found (will use ExifTool only)'
        MenuEnvNoSqlite       = ' [WARN] Neither sqlite3.exe nor Python 3 found; .lrcat reading unavailable.'
        MenuOptClean          = '  [1] Clean unrated RAW files (move to Recycle Bin)'
        MenuOptRestore        = '  [2] Restore Lightroom star ratings into JPGs'
        MenuOptRollback       = '  [3] Rollback JPG backups (restore exact original JPGs)'
        MenuOptSwitchRoot     = '  [4] Switch target photo folder'
        MenuOptSwitchLang     = '  [L] Switch language (English / 中文)'
        MenuOptExit           = '  [0] Exit'
        MenuPrompt            = 'Select an option'
        MenuInvalidOpt        = "[WARN] Invalid option '{0}'."
        MenuPressEnter        = 'Press Enter to return to menu...'
        MenuSwitchRootPrompt  = 'Enter or drop photo folder path (Enter = keep current)'
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
        RatingKeep            = '保留打星文件（检查 RAW + XMP + JPG/HIF + LR目录）'
        HeaderRawOnly         = ' 纯 RAW  : {0}'
        RawOnlyDelete         = '连同纯 RAW 一起删除 (-DeleteRawOnly)'
        RawOnlyKeep           = '保留无同名 JPG/HIF 的纯 RAW'
        HeaderCatalog         = ' LR 目录 : {0}'
        CatSkipped            = '已跳过 (-DeleteRated)'
        CatDisabled           = '已禁用 (-NoCatalog)'
        CatNotFound           = '未找到（仅使用 ExifTool 检查）'
        HeaderMode            = ' 运行模式: {0}'
        ModeDryRun            = '[预览模式：不会删除任何文件]'
        ModeLive              = '[正式模式：确认后移至回收站]'
        StatusReadingCatalog  = '  正在读取 Lightroom 目录星标...'
        StatusLoadedCatalog   = '  已从 Lightroom 目录加载 {0} 条打星/旗标记录。'
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
        PreviewKeptRated      = '  已保留（打星）   : {0} 个（以上分组中 {1} 个，更早历史分组 {2} 个，其中 LR 目录命中 {3} 个）'
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
        JpgBanner             = '===== 将 Lightroom 星标恢复写入 JPG ====='
        JpgCatalog            = ' LR 目录 : {0}'
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
        JpgReadingCat         = '正在从 Lightroom 目录读取星标...'
        JpgLoadedCat          = '已从目录加载 {0} 条路径精确匹配的打星/旗标记录。'
        JpgNoRatings          = '[提示] 目录中没有打星记录，无需恢复。'
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
        MenuTitle             = '=========== Lightroom RAW 工具箱 ==========='
        MenuCurrentRoot       = ' 当前照片目录: {0}'
        MenuCurrentLang       = ' 界面语言    : {0}'
        MenuEnvExifOk         = ' ExifTool    : 已就绪 ({0})'
        MenuEnvExifMissing    = ' ExifTool    : 未找到（请将 exiftool.exe 放入 tools\ 目录）'
        MenuEnvCatOk          = ' LR 目录     : {0}'
        MenuEnvCatLocked      = ' LR 目录     : {0}  [检测到 Lightroom 正在运行!]'
        MenuEnvCatMissing     = ' LR 目录     : 未找到（清理时仅用 ExifTool 检查）'
        MenuEnvNoSqlite       = ' [提示] 未检测到 sqlite3.exe 或 Python 3，暂时无法读取 .lrcat 目录。'
        MenuOptClean          = '  [1] 清理无星标 RAW 文件（移至回收站）'
        MenuOptRestore        = '  [2] 将 Lightroom 星标恢复写入 JPG'
        MenuOptRollback       = '  [3] 从 backups\ 一键回滚 JPG 原图备份'
        MenuOptSwitchRoot     = '  [4] 切换目标照片文件夹'
        MenuOptSwitchLang     = '  [L] 切换语言 (中文 / English)'
        MenuOptExit           = '  [0] 退出'
        MenuPrompt            = '请选择功能编号'
        MenuInvalidOpt        = "[提示] 无效选项 '{0}'，请重新输入。"
        MenuPressEnter        = '按回车返回主菜单...'
        MenuSwitchRootPrompt  = '请输入或拖入照片文件夹路径（直接回车保持不变）'
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
        if ($pname -notmatch '(^|:)(Rating|StarRating|RatingPercent|Pick)$') { continue }
        $vals = if ($prop.Value -is [System.Array]) { $prop.Value } else { @($prop.Value) }
        foreach ($v in $vals) {
            if ($null -eq $v) { continue }
            $iv = 0
            if ([int]::TryParse("$v", [ref]$iv)) {
                if ($pname -imatch '(^|:)Pick$') {
                    if ($iv -eq 1 -and $best -lt 1) { $best = 1 }
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
            $json = (& $ExifTool -fast -q -charset filename=UTF8 -json -a -G1 -FileType -XMP:Rating -EXIF:Rating -EXIF:RatingPercent -IPTC:StarRating -@ $argFile 2>$null) | Out-String
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
            $json = (& $ExifTool -fast -q -charset filename=UTF8 -json -a -G1 -FileType -XMP:Rating -Sony:Rating -EXIF:Rating -EXIF:RatingPercent -IPTC:StarRating -XMP:Pick -@ $argFile 2>$null) | Out-String
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

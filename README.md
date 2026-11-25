# Lightroom RAW Toolkit

[English](README.md) | [简体中文](README.zh-CN.md)

Safe, Recycle-Bin-first Windows PowerShell tools for photographers who shoot **RAW + JPG/HEIF** and manage ratings in **Adobe Lightroom Classic**:

1. **`Clean-RawToRecycleBin.ps1`** — Cleans old unrated RAW files to the Windows Recycle Bin while protecting starred photos across **4 independent sources** and protecting **RAW-only** shots by default.
2. **`Restore-RatingToJpg.ps1`** — Restores star ratings and pick flags from a Lightroom Classic `.lrcat` catalog back into matching JPG files without cross-folder filename collisions.

---

## Why This Exists (Pitfalls Solved)

Most simple RAW cleanup scripts only check `.xmp` sidecars. In real workflows, that causes accidental deletion of starred RAWs:

| Real-World Pitfall | How This Toolkit Protects You |
|---|---|
| Forgot to press `Ctrl+S` in Lightroom (no `.xmp` written yet) | Reads your `.lrcat` catalog **read-only** directly (supporting both `sqlite3.exe` and `Python 3`), and warns loudly if Lightroom is still open (`.lrcat.lock`). |
| Starred the `.JPG` instead of the `.ARW`/`.CR3` | Checks companion `.JPG`/`.JPEG`/`.HIF`/`.HEIC` files **and** companion `.xmp` sidecars for star ratings. |
| Shot RAW-only (no JPG backup) | **RAW-only files are kept by default** (`-DeleteRawOnly` required to delete them). |
| Mixed `.HIF`/`.JPG` + RAW with shared `.xmp` filename | Verifies XMP ownership (`SidecarForExtension`, `dc:format`, `RawFileName`) so `.HIF`/`.JPG` sidecars are **never** deleted when cleaning RAWs. |
| Corrupted / locked file or ExifTool error | Fail-safe priority: `Rated (>=1)` > `Unreadable (-1, kept)` > `Unrated (0, deletable)`. |
| Duplicate camera filenames across shoot dates (`DSC00001.JPG`) | `Restore-RatingToJpg.ps1` matches strictly by **`(folderPath + baseName)`**, never by filename alone. |
| Cloud drive re-uploading unchanged photos or `.jpg_original` clutter | Skips JPGs that already carry the target star rating, preserves `LastWriteTime` (`-P`), keeps backups centralized in `backups\` (never inside photo folders), or writes `.xmp` sidecars only (`-SidecarOnly`). |
| Camera Raw `.acr` cache clutter | `.acr` does not block RAW cleanup and is recycled together with its deleted RAW. |

---

## Requirements

- **Windows PowerShell 5.1+** (built into Windows 10/11) or PowerShell 7+
- **[ExifTool](https://exiftool.org/)** — place `exiftool.exe` + `exiftool_files\` in `tools\`, or add `exiftool` to `PATH`
- **For Lightroom `.lrcat` reading**: either **Python 3** (built-in `sqlite3`) or `sqlite3.exe` in `tools\` / `PATH`

---

## Quick Start

1. Download [ExifTool for Windows](https://exiftool.org/), rename `exiftool(-k).exe` to `exiftool.exe`, and place `exiftool.exe` + `exiftool_files\` into `tools\`.
2. Double-click **`Start-Toolkit.bat`** in the repository root (or drag any photo folder onto `Start-Toolkit.bat`) — remembers your last photo folder & language in `config.local.json` and checks ExifTool / Lightroom status on startup:
   - `[1]` **Clean unrated RAW files** — recursively scans date folders (`yyyy-MM-dd*`, or guides non-date folders to `-UseFileDate`), fast-skips ExifTool I/O on protected RAW-only files, queries your newest Lightroom `.lrcat`, shows per-folder + format distribution + top-10 file preview (`V` to view all), and requires `Y` + Enter before moving anything to the **Recycle Bin**.
   - `[2]` **Restore Lightroom star ratings to JPG** — choose between embedding into JPG or `.xmp` sidecar-only mode, optionally filter by **all folders / recent N days / single subfolder**, shows a per-folder + top-10 file preview (`V` to view all) + cloud-sync notice, writes `logs\jpg_restore_*.log`, and requires `Y` + Enter.
   - `[3]` **Rollback JPG backups** — shows backup file count & size, previews top-10 files (`V` to view all), restores exact original bytes & timestamps from `backups\jpg_restore_*`, and offers optional post-rollback backup cleanup.
   - `[4]` Switch target photo folder anytime; `[L]` toggle English / 中文 live; enter `0`/Enter to cancel sub-prompts cleanly.

---

## CLI Reference

### `scripts\Clean-RawToRecycleBin.ps1`

```powershell
# Preview cleaning RAWs older than 2026-10-26 (safe dry-run)
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -BeforeDate 2026-10-26 -DryRun

# Keep the last 60 days (inclusive), clean older RAWs, English UI
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -KeepRecentDays 60 -Lang en -DryRun

# Flat folder / non-date-folder layout (filter by file LastWriteTime)
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\Misc" -UseFileDate -BeforeDate 2026-06-01 -DryRun

# Restrict to Sony .arw only
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -RawExtensions .arw -BeforeDate 2026-10-26 -DryRun
```

| Parameter | Description |
|---|---|
| `-BeforeDate yyyy-MM-dd` | Clean items strictly earlier than this date (cutoff day is kept). |
| `-KeepRecentDays N` | Keep the last `N` days (including today), clean older items. |
| `-RootPath <path>` | Target photo folder (auto-detected if omitted). |
| `-RawExtensions` | RAW extensions to clean (default: `.arw .cr2 .cr3 .nef .nrw .raf .orf .rw2 .dng .pef .srw`). |
| `-UseFileDate` | Recursively scan all folders and filter by file `LastWriteTime` instead of `yyyy-MM-dd*` folder names. |
| `-DeleteRawOnly` | Also recycle RAWs that have no companion `.jpg`/`.jpeg`/`.hif`/`.heic` (off by default). |
| `-DeleteRated` | Also recycle star-rated RAWs (off by default). |
| `-NoCatalog` | Skip querying Lightroom `.lrcat`. |
| `-DryRun` | Preview only; touch nothing. |
| `-NoConfirm` | Skip the interactive `Y` prompt (for automation). |
| `-Lang auto\|zh\|en` | UI language (defaults to Windows UI culture). |

### `scripts\Restore-RatingToJpg.ps1`

```powershell
# Preview per-folder diff for the last 30 days (skips JPGs that already carry the same rating)
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -RecentDays 30 -DryRun

# Interactive confirm -> write into a single subfolder, preserve mtime (-P), centralized backups in backups\
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SubFolder "2026-11-22"

# Sidecar-only mode: write <name>.xmp without touching JPG bytes (zero cloud re-upload)
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SidecarOnly
```

| Parameter | Description |
|---|---|
| `-JpgRoot <path>` | Root folder containing JPGs (auto-detected if omitted). |
| `-CatalogPath <path>` | Explicit `.lrcat` path (auto-discovers newest non-backup catalog if omitted). |
| `-RecentDays N` | Limit scan to the last `N` days (by date-folder prefix or file `LastWriteTime`). |
| `-SubFolder <name>` | Limit scan to one subfolder under `-JpgRoot` (still writes backups using `-JpgRoot`-relative paths). |
| `-SidecarOnly` | Write `<base>.xmp` (`SidecarForExtension="JPG"`) instead of editing JPG bytes; skips files if `.xmp` belongs to a RAW/HEIF. |
| `-Force` | Rewrite even if the JPG/sidecar already has the identical star rating. |
| `-NoBackup` | Modify JPGs in-place without writing centralized backups into `backups\`. |
| `-BackupDir <path>` | Custom centralized backup folder (defaults to `backups\jpg_restore_<timestamp>\`). |
| `-DryRun` | Preview per-folder counts and write a dry-run log in `logs\` without modifying any file. |
| `-NoConfirm` | Skip interactive prompts (defaults to JPG mode and all folders unless `-SidecarOnly`/`-RecentDays`/`-SubFolder` is passed). |
| `-Lang auto\|zh\|en` | UI language. |

### `scripts\Rollback-JpgBackup.ps1`

```powershell
# Interactive picker over backups\jpg_restore_*
.\scripts\Rollback-JpgBackup.ps1

# Restore a specific backup folder losslessly
.\scripts\Rollback-JpgBackup.ps1 -BackupDir ".\backups\jpg_restore_20261125_121634"
```

| Parameter | Description |
|---|---|
| `-BackupDir <path>` | Specific backup folder under `backups\` (interactive list if omitted). |
| `-JpgRoot <path>` | Target photo root (auto-read from `manifest.json` if omitted). |
| `-RemoveBackupAfter` | Remove the backup folder after 100% successful rollback. |
| `-DryRun` / `-NoConfirm` | Preview-only / skip `Y` confirmation. |

---

## Running Tests

The repository includes an isolated self-test suite in `tests\Run-Tests.ps1` that creates temporary fixtures in `%TEMP%` and never touches your real photo folders:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## License

[MIT](LICENSE)

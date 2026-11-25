# RAW & JPG Photo Toolkit (`lightroom-raw-toolkit`)

[English](README.md) | [简体中文](README.zh-CN.md)

A safe, **Recycle-Bin-first** Windows toolkit for photographers who shoot **RAW + JPG/HEIF** — clean unrated old RAWs safely and sync star ratings across **Lightroom Classic**, **Capture One**, **Adobe Bridge / Camera Raw**, **Sony Imaging Edge Desktop**, and **PixCake**.

## Features

- **`[1]` Clean unrated old RAW files** — Moves old, unstarred RAW files (and companion `.acr` caches) to the **Windows Recycle Bin** while keeping every starred shot and its companion JPG/HEIF.
- **`[2]` Sync star ratings to JPG** — Writes ratings from software databases or companion RAW / `.xmp` files back into matching JPGs (visible in Windows Explorer & albums), or into `.xmp` sidecars without touching JPG bytes.
- **`[3]` One-click backup rollback** — Restores exact original JPG files and timestamps from `backups\` if you ever change your mind.

## Supported Software & Boundaries

| Software / Workflow | Cleanup `[1]` | Sync to JPG `[2]` | Usage Notes & Boundaries |
|---|---|---|---|
| **Adobe Lightroom Classic** | Supported | Supported | Reads `.lrcat` directly (even without `Ctrl+S`) plus `.xmp` sidecars. |
| **Capture One** | Supported | Supported | Reads `.cocatalogdb` / `.cosessiondb` plus synced `.xmp`. Close Capture One first for latest edits (`.cos` stores adjustments, not stars). |
| **Adobe Bridge / Camera Raw / Luminar** | Supported | Supported | Reads standard `<name>.xmp` and embedded metadata automatically. |
| **Sony Imaging Edge Desktop (IED) / Camera stars** | Supported | Supported | Reads camera-embedded Sony ratings in `.ARW`; if you rated inside IED on PC, run **File → Export Rating/Color Label to XMP** first. |
| **PixCake (像素蛋糕)** | Supported (Local DB) | Supported (Local DB) | Reads local `project.db` star/pick flags when original local paths match. Cloud-only projects without local paths/exports are not visible. |
| **Other editors (Meitu, FastStone, Photo Mechanic, etc.)** | Supported via EXIF/XMP/JPG | Supported via RAW/XMP | Any software that writes standard `.xmp` or EXIF ratings into RAW/JPG works directly; apps storing picks solely in proprietary cloud/closed caches cannot be read automatically. |

## Safety First

- **Recycle Bin only**: Never permanently deletes files — everything goes to the Windows Recycle Bin.
- **Never deletes RAW-only or unreadable shots**: Photos without a companion JPG/HEIF and corrupted/locked files are protected automatically.
- **Preview before every change**: Shows per-folder counts, RAW formats, and the first 10 files (type `V` to view all), waiting for `Y` + Enter before making any change.
- **Cloud-sync friendly**: Automatically skips JPGs that already carry the same rating, preserves original file dates, stores backups in `backups\` (no `.jpg_original` clutter in photo folders), and offers `.xmp`-only mode so JPG files are never touched.
- **Smart filename matching**: Matches strictly by folder path + filename so duplicate camera names (`DSC00001.JPG`) across shoot dates never mix up.

## Quick Start

**Requirements**: Windows 10 / 11 (ExifTool can be **auto-installed** on first launch; Python 3 or `sqlite3.exe` is used when reading desktop software databases).

1. Double-click **`Start-Toolkit.bat`** (or drag and drop any photo folder onto it).
2. If ExifTool is not installed yet, press Enter or `Y` when asked — it downloads and configures ExifTool into `tools\` automatically (or install via `winget install OliverBetz.ExifTool`).
3. Follow the menu (`[1]` Clean RAW, `[2]` Sync JPG stars, `[3]` Rollback backup, `[4]` Switch folder, `[L]` Switch English / 中文). Your last folder and language are remembered automatically.

## Supported RAW Formats

Sony (`.ARW`), Canon (`.CR2`, `.CR3`), Nikon (`.NEF`, `.NRW`), Fujifilm (`.RAF`), Olympus (`.ORF`), Panasonic (`.RW2`), Pentax (`.PEF`), Samsung (`.SRW`), DJI / Adobe (`.DNG`).

---

<details>
<summary>Advanced: CLI Usage &amp; Tests</summary>

```powershell
# Preview cleaning RAWs older than a date (dry-run, touches nothing)
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -BeforeDate 2026-10-26 -DryRun

# Preview cleaning non-date folders by file modified date
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\Misc" -UseFileDate -KeepRecentDays 60 -DryRun

# Sync star ratings from companion RAW/.xmp files only (works with no catalog DB)
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -RatingSource files -DryRun

# Preview restoring JPG stars for the last 30 days or a single subfolder
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -RecentDays 30 -DryRun
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SubFolder "2026-11-22"

# Write .xmp sidecars only without modifying JPG files
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SidecarOnly

# Roll back from a centralized backup folder
.\scripts\Rollback-JpgBackup.ps1

# Run isolated self-tests (creates temporary files only in %TEMP%)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

</details>

## License

[MIT](LICENSE)

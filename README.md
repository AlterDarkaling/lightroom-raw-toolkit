# RAW & JPG Photo Toolkit (`lightroom-raw-toolkit`)

[English](README.md) | [简体中文](README.zh-CN.md)

A safe, **Recycle-Bin-first** Windows toolkit for photographers who shoot **RAW + JPG/HEIF** — clean unrated old RAWs safely and sync star ratings across **Lightroom Classic**, **Capture One**, **Luminar Neo**, **Adobe Bridge / Camera Raw**, **Sony Imaging Edge Desktop**, **PixCake**, and **PixPretty**, with explicit compatibility boundaries for cloud/encrypted editors.

## Features

- **`[1]` Clean unrated old RAW files** — Moves old, unstarred RAW files (and companion `.acr` caches) to the **Windows Recycle Bin** while keeping every starred shot and its companion JPG/HEIF.
- **`[2]` Sync star ratings to JPG** — Writes ratings from software databases or companion RAW / `.xmp` files back into matching JPGs (visible in Windows Explorer & albums), or into `.xmp` sidecars without touching JPG bytes.
- **`[3]` One-click backup rollback** — Restores exact original JPG files and timestamps from `backups\` if you ever change your mind.

## Supported Software & Boundaries

| Software / Workflow | Cleanup `[1]` | Sync to JPG `[2]` | Usage Notes &amp; Boundaries |
|---|---|---|---|
| **Adobe Lightroom Classic** | Supported | Supported | Reads `.lrcat` directly (even without `Ctrl+S`) plus `.xmp` sidecars. |
| **Capture One** | Supported | Supported | Reads `.cocatalogdb` / `.cosessiondb` plus synced `.xmp`. Close Capture One first for latest edits (`.cos` stores adjustments, not stars). |
| **PixCake (像素蛋糕)** | Supported (Local DB) | Supported (Local DB) | Reads local `project.db` stars &amp; pick flags across standard client install paths (skipping recycled shots). Cloud-only projects without local paths/exports are not visible. |
| **PixPretty (影像之匠)** | Supported (Local DB) | Supported (Local DB) | Reads local `projects_v4.db` stars (`1–5`) and pick flags (`flag_mark`), excluding deleted shots/projects. Cloud-only selections are not visible. |
| **Luminar Neo** | Supported | Supported | Reads `.luminarneo` catalog ratings &amp; favorite (`marker`) flags (excluding Trash). Close Luminar Neo before running so changes flush to disk. |
| **Adobe Bridge / Camera Raw / FastRawViewer / Photo Mechanic** | Supported | Supported | Reads standard `<name>.xmp` and embedded metadata automatically. |
| **digiKam / darktable / XnView MP / ACDSee** | Supported via `.xmp` / written metadata | Supported via `.xmp` / written metadata | Works when XMP sidecar writing / embedded metadata sync is enabled (including `PickLabel=3` accepted flags in digiKam/darktable); update files from catalog first if ratings stay cache-only. |
| **Sony Imaging Edge Desktop (IED) / Camera stars** | Supported (with export step) | Supported (with export step) | Reads camera-embedded Sony ratings in `.ARW`; if you rated inside IED on PC, run **File → Export Rating/Color Label to XMP** first. |
| **Magic Mirror 5 / 魔镜修图 5 (Haicaoyun)** | Not directly readable | Not directly readable | Uses an encrypted local database (`magic_mirror.realm`) for client jobs. Export culled outputs first or do initial star culling in LR / Bridge / PixCake / PixPretty before cleanup. |
| **Meitu Yunxiu (美图云修) / nEO iMAGING (光影魔术手)** | Only after standard metadata export | Only after standard metadata export | Keeps picks/edits in proprietary project or cloud storage without standard `.xmp`; export finished JPGs or use an XMP-capable culler before deleting RAWs. |
| **PixCheese (像素芝士) / Xiangxiangpai / OOTU** | Not cloud-readable | Not cloud-readable | Desktop tools handle upload/download/print queues while selections live in the cloud. Download or sync client selections before cleaning RAWs. |
| **Eagle / Billfish** | Only when linked in-place | — | If assets are copied into a separate library vault, ratings do not write back to your original shoot folder. |

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

# Lightroom RAW Toolkit

[English](README.md) | [简体中文](README.zh-CN.md)

A safe, **Recycle-Bin-first** Windows tool for photographers who shoot **RAW + JPG/HEIF** and manage ratings in **Adobe Lightroom Classic**.

## Features

- **`[1]` Clean unrated old RAW files** — Moves old, unstarred RAW files to the **Windows Recycle Bin** to save disk space while keeping every starred shot and its companion JPG/HEIF.
- **`[2]` Restore Lightroom ratings to JPG** — Writes your Lightroom stars & picks back into matching JPGs (visible in Windows Explorer and photo albums), or into `.xmp` sidecar files without touching JPG bytes.
- **`[3]` One-click backup rollback** — Restores exact original JPG files and timestamps from backups if you ever change your mind.

## Safety First

- **Recycle Bin only**: Never permanently deletes files — everything goes to the Windows Recycle Bin.
- **Checks all star sources**: Reads Lightroom Classic catalogs, `.xmp` sidecars, and companion JPG/HEIF ratings (even if you forgot to press `Ctrl+S` in Lightroom).
- **Never deletes RAW-only or unreadable shots**: Photos without a companion JPG/HEIF and corrupted/locked files are protected automatically.
- **Preview before every change**: Shows per-folder counts, RAW formats, the first 10 files (type `V` to view all), and waits for `Y` + Enter before making any change.
- **Cloud-sync friendly**: Automatically skips JPGs that already carry the same rating, preserves original file dates, stores backups in `backups\` (no `.jpg_original` clutter in your photo folders), and offers `.xmp`-only mode so JPG files are never modified.
- **Smart filename matching**: Matches strictly by folder path + filename so duplicate camera names (`DSC00001.JPG`) across different shoot dates never mix up.

## Quick Start

**Requirements**: Windows 10 / 11 (ExifTool can be **auto-installed** on first launch; Python 3 or `sqlite3.exe` is used if reading Lightroom catalogs).

1. Double-click **`Start-Toolkit.bat`** (or drag and drop any photo folder onto it).
2. If ExifTool is not installed yet, press Enter or `Y` when asked — the toolkit automatically downloads and configures it into `tools\` (or run `winget install OliverBetz.ExifTool` / place `exiftool.exe` in `tools\` manually).
3. Follow the menu (`[1]` Clean RAW, `[2]` Restore JPG stars, `[3]` Rollback backup, `[4]` Switch folder, `[L]` Switch English / 中文). Your last folder and language are remembered automatically.

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

# Preview restoring JPG stars for the last 30 days (or a single subfolder)
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

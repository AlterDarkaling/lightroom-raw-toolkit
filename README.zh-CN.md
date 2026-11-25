# Lightroom RAW Toolkit

[English](README.md) | [简体中文](README.zh-CN.md)

一套专为 **RAW + JPG/HEIF 双格式拍摄** 和 **Adobe Lightroom Classic** 用户设计的安全清理与星标恢复工具（Windows PowerShell）：

1. **`Clean-RawToRecycleBin.ps1`** — 按日期清理无星标 RAW 至 **Windows 回收站**，从 **4 个来源**交叉核对星标，并默认保护没有 JPG 的纯 RAW。
2. **`Restore-RatingToJpg.ps1`** — 从 Lightroom `.lrcat` 目录中读取星标与留用旗标，按**精确路径**恢复写入对应 JPG 文件（支持 Windows 资源管理器显示星级）。

---

## 解决了哪些真实痛点？

很多同类小脚本只认 `.xmp` 边车文件，实际使用极易误删：

| 常见翻车场景 | 本工具的防护机制 |
|---|---|
| 在 Lightroom 打了星但忘了按 `Ctrl+S` 保存 `.xmp` | **直接只读查询 `.lrcat` 数据库**（支持 `sqlite3.exe` 或 `Python 3`），检测到 Lightroom 正在运行（`.lrcat.lock`）还会主动警告。 |
| 星标不小心打在了 `.JPG`（或 JPG 专属 `.xmp`）上 | 同时检查同名 `.JPG`/`.JPEG`/`.HIF`/`.HEIC` **以及**非 RAW 专属的 `.xmp` 上的星标，有星照样保住 RAW。 |
| 某些照片只拍了单 RAW（无 JPG） | **默认保留纯 RAW**（除非显式传入 `-DeleteRawOnly`）。 |
| 混拍 `.HIF`/`.JPG` 与 RAW 时共享 `<文件名>.xmp` | 通过 XMP 内部 `SidecarForExtension`、`dc:format`、`RawFileName` 校验归属，**绝不误删 `.HIF`/`.JPG` 的边车**。 |
| 文件损坏 / 占用 / ExifTool 异常 | 安全兜底优先级：`已打星 (>=1)` > `读取失败 (-1，保留)` > `确认无星 (0，才可删)`。 |
| 不同日期文件夹存在大量同名照片（如 `DSC00001.JPG`） | `Restore-RatingToJpg.ps1` 严格按 **`文件夹路径 + 文件名`** 匹配，绝不跨天串星。 |
| 写入星标导致网盘大规模重传或残留 `.jpg_original` 垃圾文件 | 自动**跳过已是同星标的 JPG**、写入时保留原修改时间（`-P`）、原图集中备份到 `backups\`（不在照片目录留 `_original`），或可选 `-SidecarOnly` 仅写 `.xmp` 完全不改 JPG。 |
| Camera Raw 生成的 `.acr` 修图缓存 | 不阻止无星 RAW 清理；删除 RAW 时自动连带移入回收站，不留孤儿缓存。 |

---

## 运行环境

- **Windows PowerShell 5.1+**（Windows 10/11 自带）或 PowerShell 7+
- **[ExifTool](https://exiftool.org/)**：将 `exiftool.exe` 与 `exiftool_files\` 放入 `tools\` 目录，或加入系统 `PATH`
- **读取 Lightroom `.lrcat`**：电脑装有 **Python 3**（自带 `sqlite3`），或将 `sqlite3.exe` 放入 `tools\` / `PATH`

---

## 快速上手

1. 从 [ExifTool 官网](https://exiftool.org/) 下载 Windows 版，将 `exiftool(-k).exe` 重命名为 `exiftool.exe`，连同 `exiftool_files\` 一起放入 `tools\` 目录。
2. 双击根目录下的 **`Start-Toolkit.bat`**（或直接把任意照片文件夹拖到 `Start-Toolkit.bat` 图标上）——自动记忆上次选择的照片目录与语言（存在 `config.local.json`），并在菜单顶部实时检查 `ExifTool` 与 Lightroom 目录状态：
   - `[1]` **清理无星标 RAW 文件**：自动递归扫描日期文件夹内各级子目录（遇到非日期目录也会主动引导按文件修改日期扫描），自动跳过纯 RAW 的无效读取以提速，交叉核对最新 `.lrcat` 与照片星标；展示分组统计、**待删格式分布**与**前 10 个文件明细**（确认时支持输 `V` 看全部），必须输入 `Y` + 回车才会移入**回收站**。
   - `[2]` **将 Lightroom 星标恢复写入 JPG**：支持选择写入 JPG 或 `.xmp` 边车、支持限定范围（**全部 / 最近 N 天 / 单个子文件夹**），展示预览与前 10 条明细（输 `V` 看全部）及网盘提示并记录 `logs\jpg_restore_*.log`，输入 `Y` + 回车才会正式写入。
   - `[3]` **一键回滚 JPG 原图备份**：列出每份备份的文件数与占用大小，支持前 10 条及 `V` 查看明细，从 `backups\` 无损还原原字节与原修改时间，回滚成功后可选清理该份备份释放空间。
   - `[4]` 随时切换目标照片目录；`[L]` 实时切换中英文；各子菜单支持输入 `0` 或直接回车安全取消。

---

## 命令行常用示例

### `scripts\Clean-RawToRecycleBin.ps1`

```powershell
# 预览清理早于 2026-10-26 的无星 RAW（只读预览，不删文件）
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -BeforeDate 2026-10-26 -DryRun

# 保留最近 60 天（含今天），清理更早的，指定中文界面
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -KeepRecentDays 60 -Lang zh -DryRun

# 非日期命名文件夹：按文件修改时间筛选
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\Misc" -UseFileDate -BeforeDate 2026-06-01 -DryRun

# 仅清理索尼 .arw 格式
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -RawExtensions .arw -BeforeDate 2026-10-26 -DryRun
```

| 参数 | 说明 |
|---|---|
| `-BeforeDate yyyy-MM-dd` | 清理早于该日期的照片（不含当天）。 |
| `-KeepRecentDays N` | 保留最近 `N` 天（含今天），清理更早的。 |
| `-RootPath <路径>` | 指定照片根目录（省略时自动向上查找）。 |
| `-RawExtensions` | 要处理的 RAW 扩展名（默认支持 `.arw .cr2 .cr3 .nef .nrw .raf .orf .rw2 .dng .pef .srw`）。 |
| `-UseFileDate` | 递归扫描所有目录并按文件修改时间筛选（适合不按日期建文件夹的图库）。 |
| `-DeleteRawOnly` | 连同没有同名 JPG/HIF 的纯 RAW 一起删除（默认关闭）。 |
| `-DeleteRated` | 连同已打星 RAW 一起删除（默认关闭）。 |
| `-NoCatalog` | 不查询 Lightroom `.lrcat` 目录。 |
| `-DryRun` | 仅预览并写日志，不删除任何文件。 |
| `-NoConfirm` | 跳过最后的 `Y` 确认提示（自动化脚本用，慎用）。 |
| `-Lang auto\|zh\|en` | 界面语言（默认跟随系统语言）。 |

### `scripts\Restore-RatingToJpg.ps1`

```powershell
# 只读预览最近 30 天的星标差异（自动跳过已有同星标的 JPG）
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -RecentDays 30 -DryRun

# 仅处理单个日期子文件夹，确认后写入 JPG（保留修改时间、集中备份到 backups\）
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SubFolder "2026-11-22"

# 仅写 .xmp 边车模式（完全不改 JPG 字节，零网盘重传）
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SidecarOnly
```

| 参数 | 说明 |
|---|---|
| `-JpgRoot <路径>` | JPG 根目录（省略时自动识别）。 |
| `-CatalogPath <路径>` | 手动指定 `.lrcat` 路径（省略时自动找最新非备份目录）。 |
| `-RecentDays N` | 仅处理最近 `N` 天的照片（按日期文件夹或文件修改时间过滤）。 |
| `-SubFolder <名>` | 仅处理指定子文件夹（`backups\` 仍保持完整相对路径结构）。 |
| `-SidecarOnly` | 仅写 `<文件名>.xmp`（标记归属 JPG），完全不改 JPG 原文件；如遇同名 RAW/HEIF 边车则自动跳过防覆盖。 |
| `-Force` | 强制重写所有匹配项（不跳过已有相同星标的文件）。 |
| `-NoBackup` | 不向 `backups\` 目录复制原图备份，直接原地写入。 |
| `-BackupDir <路径>` | 自定义集中备份目录（默认为工具箱 `backups\jpg_restore_<时间戳>\`）。 |
| `-DryRun` | 仅扫描预览并在 `logs\` 生成预览日志，不修改任何文件。 |
| `-NoConfirm` | 跳过交互提示（默认写入 JPG、扫描全部，或配合 `-SidecarOnly`/`-RecentDays`/`-SubFolder` 使用）。 |
| `-Lang auto\|zh\|en` | 界面语言（默认跟随系统语言）。 |

### `scripts\Rollback-JpgBackup.ps1`

```powershell
# 交互式列出 backups\jpg_restore_* 供选择回滚
.\scripts\Rollback-JpgBackup.ps1

# 指定备份目录一键无损还原
.\scripts\Rollback-JpgBackup.ps1 -BackupDir ".\backups\jpg_restore_20261125_121634"
```

| 参数 | 说明 |
|---|---|
| `-BackupDir <路径>` | 要恢复的备份目录（省略时交互选择）。 |
| `-JpgRoot <路径>` | 恢复目标根目录（默认自动读取 `manifest.json`）。 |
| `-RemoveBackupAfter` | 全部恢复成功后顺带删除该次备份目录。 |
| `-DryRun` / `-NoConfirm` | 仅预览 / 跳过 `Y` 确认。 |

---

## 自动化测试

仓库自带隔离测试套件 `tests\Run-Tests.ps1`，测试数据全部生成在系统临时目录 `%TEMP%`，绝不触碰真实照片目录：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

## 开源协议

[MIT License](LICENSE)

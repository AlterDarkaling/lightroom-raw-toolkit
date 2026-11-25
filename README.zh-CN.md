# Lightroom RAW 工具箱

[English](README.md) | [简体中文](README.zh-CN.md)

一款专为 **RAW + JPG/HEIF 双格式拍摄** 和 **Adobe Lightroom Classic** 用户设计的安全工具：先把无星老旧 RAW 移入**Windows 回收站**，也能把 Lightroom 里的星标安全写回对应的 JPG 照片。

## 核心功能

- **`[1]` 清理无星标 RAW 文件**：按日期或最近天数清理老旧无星 RAW 至 **Windows 回收站**，保留所有打星照片和对应 JPG/HEIF（并自动清理残留 `.acr`）。
- **`[2]` 将 Lightroom 星标恢复写入 JPG**：把目录里的星标与留用旗标写回对应 JPG（让 Windows 资源管理器和相册也能显示星级），或可选只写 `.xmp` 边车完全不改 JPG。
- **`[3]` 一键回滚 JPG 原图备份**：如果写完后悔或触发了网盘重传，可从工具箱备份中一键无损还原原图和原修改时间。

## 安全设计

- **只进回收站**：绝不直接永久删除文件，清理错了随时去回收站找回。
- **多方核对防误删**：同时检查 Lightroom 目录数据库（忘了按 `Ctrl+S` 也能识别）、`.xmp` 边车和同名 JPG/HEIF 上的星标。
- **纯 RAW 与损坏文件自动保护**：没有同名 JPG/HEIF 的纯 RAW，以及损坏或被占用的文件，默认全部安全保留。
- **操作前先看预览**：每次都会展示文件夹汇总、待删格式分布和前 10 个文件明细（支持输入 `V` 看全部），必须手动输入 `Y` + 回车才会真正执行。
- **对备份网盘友好**：写星标时自动跳过已有相同星标的 JPG、自动保留原文件修改时间、原图备份统一放在工具箱 `backups\` 目录（不在照片文件夹里留 `.jpg_original` 垃圾文件）；也支持只写 `.xmp` 边车，做到零 JPG 改动。
- **同名照片不串星**：严格按“文件夹路径 + 文件名”匹配，不同日期的 `DSC00001.JPG` 绝不会串星。

## 快速上手

**准备环境**：Windows 10 / 11（首次启动可**自动安装 ExifTool**；读取 Lightroom 目录需要 Python 3 或 `sqlite3.exe`）。

1. 双击根目录下的 **`Start-Toolkit.bat`**（或直接把照片文件夹拖到 `Start-Toolkit.bat` 图标上）。
2. 如果还没装 ExifTool，启动时会主动询问，直接按回车或 `Y` 即可自动从官网下载并配置进 `tools\`（也可在终端运行 `winget install OliverBetz.ExifTool`，或手动下载放入 `tools\`）。
3. 按菜单选择即可：`[1]` 清理 RAW、`[2]` 恢复 JPG 星标、`[3]` 一键回滚备份、`[4]` 切换照片文件夹、`[L]` 切换中英文。工具会自动记住你上次使用的文件夹和语言。

## 支持的 RAW 格式

索尼 (`.ARW`)、佳能 (`.CR2`, `.CR3`)、尼康 (`.NEF`, `.NRW`)、富士 (`.RAF`)、奥林巴斯 (`.ORF`)、松下 (`.RW2`)、宾得 (`.PEF`)、三星 (`.SRW`)、大疆 / Adobe (`.DNG`)。

---

<details>
<summary>进阶：命令行用法与测试</summary>

```powershell
# 预览清理早于指定日期的无星 RAW（仅预览，不删文件）
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\2026" -BeforeDate 2026-10-26 -DryRun

# 非日期命名文件夹：按文件修改时间保留最近 60 天
.\scripts\Clean-RawToRecycleBin.ps1 -RootPath "D:\Photos\Misc" -UseFileDate -KeepRecentDays 60 -DryRun

# 预览恢复最近 30 天或单个子文件夹的 JPG 星标
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -RecentDays 30 -DryRun
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SubFolder "2026-11-22"

# 仅写 .xmp 边车（完全不改动 JPG 文件）
.\scripts\Restore-RatingToJpg.ps1 -JpgRoot "D:\Photos\2026" -SidecarOnly

# 从 backups\ 交互选择备份并回滚
.\scripts\Rollback-JpgBackup.ps1

# 运行隔离自动化测试（所有测试文件仅在 %TEMP% 中生成）
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
```

</details>

## 开源协议

[MIT License](LICENSE)

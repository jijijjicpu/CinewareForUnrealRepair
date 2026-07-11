# Cineware for Unreal Repair

> Fix the **Failed to locate Cineware. Please install Maxon Cinema 4D 2026.** popup in Unreal Engine 5.7, when Cinema 4D 2026 is installed to a non-default path (e.g. the D drive).
>
> 修复 Cinema 4D 2026 安装在非默认路径（如 D 盘）时，Unreal Engine 5.7 的 CinewareForUnreal 插件反复弹出的 **Failed to locate Cineware. Please install Maxon Cinema 4D 2026.** 错误。

[![Platform](https://img.shields.io/badge/platform-Windows%20x64-0078D4)]() [![UE](https://img.shields.io/badge/Unreal-5.7-0E1128)]() [![C4D](https://img.shields.io/badge/Cinema%204D-2026-011A6C)]() [![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**Links / 链接:** [Interactive Guide / 交互式教程](docs/index.html) · [Download fix script / 下载修复脚本](scripts/fix-cineware.bat)

---

## 中文

### 快速修复

**方式 A（推荐）—— 一键脚本**

1. 下载 [`scripts/fix-cineware.bat`](scripts/fix-cineware.bat)
2. 双击运行（脚本会自动申请管理员权限，并自动检测 C4D 2026 的安装路径，装在哪个盘都行）
3. 重启 UE 编辑器，弹窗消失

**方式 B —— 手动一行命令**

在**管理员**命令提示符（cmd）里执行（把第二个路径换成你真实的 C4D 2026 安装目录）：

```cmd
mklink /J "C:\Program Files\Maxon Cinema 4D 2026" "D:\Maxon Cinema 4D 2026"
```

### 问题原因

当 Cinema 4D 2026 安装在非默认路径时，UE 的 CinewareForUnreal 插件找不到 Cineware 运行时（`cineware.dll`）。插件的核心 DLL **硬编码**在 `C:\Program Files\Maxon Cinema 4D 2026\cineware.dll` 这个默认路径查找，而非默认安装下该路径不存在，于是弹窗并降级为旧的导入器。

本工具在 `C:\Program Files\` 下创建一个**目录连接（junction）**，指向 C4D 真实的安装目录，让插件硬编码的路径透明解析到真实文件。

> **Direct Link 实时同步不受此问题影响**（走独立通道）。只要 C4D 文件已保存，Direct Link 就能正常同步模型——它和这个弹窗无关。

### 适用条件

| 项            | 要求                       |
| ------------- | -------------------------- |
| Cinema 4D     | 2026（安装在非默认路径）   |
| Unreal Engine | 5.7                        |
| 插件          | Cineware for Unreal 2026.x |
| 系统          | Windows 10 / 11 x64        |

### 回滚

双击 [`scripts/undo-fix.bat`](scripts/undo-fix.bat)，或在管理员 cmd 执行：

```cmd
rmdir "C:\Program Files\Maxon Cinema 4D 2026"
```

只会删除 junction 链接，**不会动 C4D 的真实文件**，C4D 照常运行。

### 常见问题

**会影响 C4D 本身吗？** 不会。junction 是透明的目录链接，C4D 仍从原路径正常运行，更新与卸载都不受影响。

**C4D 升级或重装后怎么办？** 如果 C4D 的安装目录变了，先运行 `undo-fix.bat` 删除旧 junction，再运行 `fix-cineware.bat` 自动重建。

**弹窗和 Direct Link 没模型有关系吗？** 没有。Direct Link 没模型通常是因为 C4D 文件没保存；弹窗只影响 `.c4d` 文件直接拖入 UE 的导入功能。

---

## English

### Quick Fix

**Method A (recommended) — one-click script**

1. Download [`scripts/fix-cineware.bat`](scripts/fix-cineware.bat)
2. Double-click to run (it auto-elevates to admin and auto-detects the C4D 2026 install path — works no matter which drive C4D is on)
3. Restart the UE editor, the popup is gone

**Method B — manual one-liner**

Run in an **Administrator** Command Prompt (replace the second path with your real C4D 2026 install directory):

```cmd
mklink /J "C:\Program Files\Maxon Cinema 4D 2026" "D:\Maxon Cinema 4D 2026"
```

### Root Cause

When Cinema 4D 2026 is installed to a non-default path, the CinewareForUnreal plugin cannot locate the Cineware runtime (`cineware.dll`). The core DLL of the plugin looks it up at the **hardcoded** default path `C:\Program Files\Maxon Cinema 4D 2026\cineware.dll`, which does not exist for non-default installs, so it pops the error and falls back to the legacy importer.

This tool creates a **directory junction** under `C:\Program Files\` pointing to the real C4D install directory, so the hardcoded path transparently resolves to the real file.

> **Direct Link live sync is not affected** by this issue (it uses a separate channel). As long as the C4D file is saved, Direct Link syncs meshes normally — it has nothing to do with this popup.

### Requirements

| Item          | Requirement                            |
| ------------- | -------------------------------------- |
| Cinema 4D     | 2026 (installed to a non-default path) |
| Unreal Engine | 5.7                                    |
| Plugin        | Cineware for Unreal 2026.x             |
| OS            | Windows 10 / 11 x64                    |

### Undo

Double-click [`scripts/undo-fix.bat`](scripts/undo-fix.bat), or in an Administrator cmd:

```cmd
rmdir "C:\Program Files\Maxon Cinema 4D 2026"
```

This removes only the junction link — **the real C4D files are untouched**, and C4D keeps running.

### FAQ

**Does it affect C4D itself?** No. The junction is a transparent directory link; C4D keeps running from its original path, and updates and uninstall are unaffected.

**What if C4D is upgraded or reinstalled?** If the C4D install path changes, run `undo-fix.bat` to remove the old junction, then `fix-cineware.bat` to rebuild it automatically.

**Is the popup related to Direct Link showing no mesh?** No. Missing mesh in Direct Link is usually because the C4D file was not saved; the popup only affects direct `.c4d` file import into UE.

---

## Project Structure / 项目结构

```
CinewareForUnrealRepair/
├── README.md                  # This file
├── LICENSE                    # MIT
├── docs/
│   └── index.html             # Interactive bilingual guide / 交互式教程
└── scripts/
    ├── fix-cineware.bat       # Double-click launcher / 双击启动器
    ├── fix-cineware.ps1       # Core: auto-detect + create junction
    └── undo-fix.bat           # Undo launcher / 回滚启动器
```

## Disclaimer / 免责声明

This is **not** an official Maxon or Epic Games tool. Use at your own risk. The junction approach is non-destructive and fully reversible, but the author is not responsible for any damage.

本工具**并非** Maxon 或 Epic Games 官方工具，使用者风险自负。junction 方式非破坏性且完全可逆，但作者不对任何损失负责。

## License

[MIT](LICENSE) © 2026 YOUR_NAME

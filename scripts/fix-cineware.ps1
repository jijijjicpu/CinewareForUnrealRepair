<#
.SYNOPSIS
    Cineware for Unreal 弹窗修复脚本 / Fix the "Failed to locate Cineware" popup
.DESCRIPTION
    当 Cinema 4D 2026 安装在非默认路径（如 D 盘）时，UE 5.7 的 CinewareForUnreal
    插件每次启动会弹窗 "Failed to locate Cineware. Please install Maxon Cinema 4D 2026."，
    且 .c4d 文件导入降级失效。

    根因：插件 DLL 硬编码在 C:\Program Files\Maxon Cinema 4D 2026\cineware.dll 查找。
    修复：本脚本自动检测 C4D 2026 真实安装路径，在 C:\Program Files\ 下创建指向它的
    目录连接 (junction)，让插件硬编码路径透明解析到真实文件。

    When Cinema 4D 2026 is installed to a non-default path, UE 5.7's CinewareForUnreal
    plugin pops "Failed to locate Cineware" on every launch. This script auto-detects
    the real C4D 2026 path and creates a directory junction under C:\Program Files\ so
    the plugin's hardcoded path resolves to the real cineware.dll.
.PARAMETER Undo
    撤销修复（删除 junction，不影响 C4D 原始文件）/ Undo the fix (remove the junction)
.EXAMPLE
    .\fix-cineware.ps1            # 执行修复 / Apply the fix
    .\fix-cineware.ps1 -Undo      # 撤销修复 / Undo the fix
.NOTES
    需要管理员权限（脚本会自动提权）/ Requires admin (auto-elevates)
    Author: YOUR_NAME   |   License: MIT
#>
#Requires -Version 5.1
param([switch]$Undo)

# ========== 配置 / Config ==========
$C4D_VERSION_PATTERN = '2026.*'                  # 匹配 C4D 2026 / Match C4D 2026
$JUNCTION_NAME       = 'Maxon Cinema 4D 2026'
$JUNCTION_PARENT     = 'C:\Program Files'
$MAXON_REG           = 'HKLM:\SOFTWARE\Maxon'

# ========== 编码 / Encoding（确保中文不乱码 / ensure Chinese displays correctly）==========
if ($Host.Name -eq 'ConsoleHost') {
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
}
$OutputEncoding = [System.Text.Encoding]::UTF8

# ========== 输出函数 / Output helpers（中英双语一行 / bilingual one-liner）==========
function Write-Info  { param($zh, $en) Write-Host "[-] $zh / $en" -ForegroundColor Cyan }
function Write-OK    { param($zh, $en) Write-Host "[OK] $zh / $en" -ForegroundColor Green }
function Write-Warn2 { param($zh, $en) Write-Host "[!] $zh / $en" -ForegroundColor Yellow }
function Write-Err2  { param($zh, $en) Write-Host "[X] $zh / $en" -ForegroundColor Red }
function Write-Note  { param($m) Write-Host "    $m" -ForegroundColor DarkGray }

# ========== 提权 / Elevation ==========
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevate {
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
    if ($Undo) { $argList += '-Undo' }
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList -ErrorAction Stop
    } catch {
        Write-Err2 '需要管理员权限，但提权被取消' 'Admin required, but elevation was cancelled'
        Read-Host "按回车退出 / Press Enter to exit"
    }
    exit
}

# ========== 检测 C4D 2026 真实路径 / Detect real C4D 2026 path ==========
function Find-C4D2026Path {
    if (-not (Test-Path $MAXON_REG)) { return $null }
    foreach ($k in (Get-ChildItem $MAXON_REG -ErrorAction SilentlyContinue)) {
        $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
        if ($p.Version -and "$($p.Version)" -like $C4D_VERSION_PATTERN) {
            $loc = $p.Location
            if ($loc -and (Test-Path $loc)) { return $loc }
        }
    }
    return $null
}

# ========== 判断路径是否为 junction / Check if path is a junction ==========
function Test-IsJunction {
    param($Path)
    if (-not (Test-Path $Path)) { return $false }
    try {
        $item = Get-Item $Path -Force
        return ($item.LinkType -eq 'Junction') -or ($item.Attributes.ToString() -match 'ReparsePoint')
    } catch { return $false }
}

# ============================================================
#  主逻辑 / Main
# ============================================================
$junctionPath = Join-Path $JUNCTION_PARENT $JUNCTION_NAME

# 提权 / Elevate if needed
if (-not (Test-Admin)) {
    Write-Warn2 '需要管理员权限，正在提权...' 'Administrator required, elevating...'
    Invoke-Elevate
}

Write-Host ""
Write-Host "=== Cineware for Unreal Fix Tool ===" -ForegroundColor White
Write-Host "=== Cineware for Unreal 修复工具 ===" -ForegroundColor White
Write-Host ""

if ($Undo) {
    # ---------------- 回滚 / Undo ----------------
    Write-Info '回滚模式：删除 junction' 'Undo mode: remove junction'
    Write-Host ""
    if (-not (Test-Path $junctionPath)) {
        Write-Warn2 'junction 不存在，无需回滚' 'Junction does not exist, nothing to undo'
    }
    elseif (-not (Test-IsJunction -Path $junctionPath)) {
        Write-Err2 "$junctionPath 不是 junction" "$junctionPath is NOT a junction"
        Write-Note '它可能是真实的 C4D 安装目录，脚本拒绝删除以防破坏'
        Write-Note 'It may be the real C4D install dir — refusing to delete for safety'
        Write-Note '如确认需要删除，请手动操作 / Delete manually if you are sure'
    }
    else {
        try {
            cmd /c rmdir "`"$junctionPath`"" | Out-Null
            if (-not (Test-Path $junctionPath)) {
                Write-OK '已删除 junction' 'Junction removed'
                Write-Note 'C4D 仍正常在原路径运行 / C4D still runs from its original path'
            }
            else {
                Write-Err2 '删除失败' 'Removal failed'
            }
        } catch {
            Write-Err2 "删除异常: $_" "Exception: $_"
        }
    }
}
else {
    # ---------------- 修复 / Fix ----------------
    Write-Info '扫描注册表，定位 C4D 2026...' 'Scanning registry for C4D 2026...'
    $c4dPath = Find-C4D2026Path
    if (-not $c4dPath) {
        Write-Err2 '未在注册表找到 C4D 2026 安装信息' 'C4D 2026 install info not found in registry'
        Write-Note '请确认已安装 Cinema 4D 2026 / Ensure Cinema 4D 2026 is installed'
        Read-Host "按回车退出 / Press Enter to exit"; exit 1
    }
    Write-OK "找到 C4D 2026: $c4dPath" "Found C4D 2026: $c4dPath"

    $cinewareDll = Join-Path $c4dPath 'cineware.dll'
    if (-not (Test-Path $cinewareDll)) {
        Write-Err2 "未找到 cineware.dll: $cinewareDll" "cineware.dll not found"
        Write-Note '该路径可能不是有效的 C4D 2026 根目录'
        Write-Note 'This may not be a valid C4D 2026 root directory'
        Read-Host "按回车退出 / Press Enter to exit"; exit 1
    }
    Write-Host ""

    if (Test-Path $junctionPath) {
        # 目标已存在 / Target already exists
        if (Test-IsJunction -Path $junctionPath) {
            $target = (Get-Item $junctionPath -Force).Target
            Write-OK 'junction 已存在，无需重复修复' 'Junction already exists, already fixed'
            Write-Note "当前指向 / currently targets: $target"
            if ("$target" -ne "$c4dPath") {
                Write-Warn2 'junction 指向与当前 C4D 路径不一致' 'Junction target differs from current C4D path'
                Write-Note '如需更新，请先运行 undo-fix，再运行本脚本'
                Write-Note 'To update, run undo-fix first, then this script again'
            }
        }
        else {
            Write-Err2 "$junctionPath 已存在且不是 junction" "$junctionPath exists but is NOT a junction"
            Write-Note '很可能 C4D 已装在默认路径，本来就不需要修复'
            Write-Note 'C4D is likely in the default path — no fix is needed'
            Write-Note '脚本不会覆盖真实目录，已退出 / Refusing to overwrite a real directory'
            Read-Host "按回车退出 / Press Enter to exit"; exit 1
        }
    }
    else {
        # 创建 junction / Create the junction
        Write-Info '创建目录连接...' 'Creating directory junction...'
        Write-Note "$junctionPath"
        Write-Note "  ==>  $c4dPath"
        try {
            $mkOut = cmd /c mklink /J "`"$junctionPath`"" "`"$c4dPath`"" 2>&1
            if (Test-Path (Join-Path $junctionPath 'cineware.dll')) {
                Write-OK '修复成功！' 'Fix successful!'
                Write-Note "mklink 输出 / mklink output: $($mkOut.Trim())"
            }
            else {
                Write-Err2 'junction 已创建但验证失败' 'Junction created but verification failed'
                Write-Note "$mkOut"
                Read-Host "按回车退出 / Press Enter to exit"; exit 1
            }
        } catch {
            Write-Err2 "创建异常: $_" "Exception: $_"
            Read-Host "按回车退出 / Press Enter to exit"; exit 1
        }
    }
}

Write-Host ""
Write-Info '请重启 UE 编辑器使修复生效' 'Restart the UE editor for the fix to take effect'
Write-Host ""
Read-Host "按回车关闭 / Press Enter to close"

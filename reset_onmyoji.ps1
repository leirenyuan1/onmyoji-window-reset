# ============================================================
#  一键复位 onmyoji.exe（阴阳师）窗口到初始状态
#  基准测试环境：笔记本屏幕分辨率 2880x1800，系统缩放 200%
#  初始状态基准：位置 (288, 198)  大小 2304 x 1358
#  如需更换基准，修改下方 Init* 常量即可
#  按进程名查找窗口，不依赖 PID
# ============================================================

$ErrorActionPreference = "Stop"

# 确保中文输出正常（无论从哪个窗口启动）
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---------- 初始状态基准（可自行修改）----------
$InitLeft   = 288
$InitTop    = 198
$InitWidth  = 2304
$InitHeight = 1358

# ---------- 定义 Win32 API ----------
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win32Api {
    // 进程级 DPI 感知（SYSTEM_DPI_AWARE），坐标按物理像素计算
    [DllImport("shcore.dll")]
    public static extern int SetProcessDpiAwareness(int value);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsZoomed(IntPtr hWnd);


    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@

[Win32Api]::SetProcessDpiAwareness(1) | Out-Null

# 弹窗提示辅助函数（仅在异常/警告时调用）
function Show-Alert([string]$message, [string]$title = "阴阳师窗口复位", [int]$icon = 48) {
    try {
        $ws = New-Object -ComObject WScript.Shell
        $ws.Popup($message, 0, $title, $icon) | Out-Null
    } catch {}
}

# ---------- 查找 onmyoji 主窗口（按名称，不依赖 PID）----------
$proc = Get-Process -Name "onmyoji" -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1

if ($null -eq $proc) {
    Show-Alert "未检测到《阴阳师》运行进程（onmyoji.exe）或未找到可见主窗口。`n`n请先启动游戏并完全进入主界面后再试！" "阴阳师窗口复位 - 提示" 48
    exit 1
}

$hWnd = $proc.MainWindowHandle
Write-Host ("找到进程: onmyoji (PID: {0})" -f $proc.Id)

# ---------- 若最小化/最大化则先还原 ----------
if ([Win32Api]::IsIconic($hWnd)) { [Win32Api]::ShowWindow($hWnd, 9) | Out-Null }
if ([Win32Api]::IsZoomed($hWnd))  { [Win32Api]::ShowWindow($hWnd, 9) | Out-Null }
Start-Sleep -Milliseconds 300

# ---------- 执行复位 ----------
$SWP_SHOWWINDOW = 0x0040
$SWP_NOZORDER   = 0x0004
# 仅移动位置和调整大小：不改变 z-order、不置顶、不抢前台
$ok = [Win32Api]::SetWindowPos($hWnd, [IntPtr]::Zero, $InitLeft, $InitTop, $InitWidth, $InitHeight, $SWP_SHOWWINDOW -bor $SWP_NOZORDER)

# ---------- 校验实际结果 ----------
Start-Sleep -Milliseconds 400
$rc = New-Object Win32Api+RECT
[Win32Api]::GetWindowRect($hWnd, [ref]$rc) | Out-Null
$curL = $rc.Left;  $curT = $rc.Top
$curW = $rc.Right - $rc.Left
$curH = $rc.Bottom - $rc.Top

if (-not $ok) {
    Show-Alert "窗口位置复位失败（Win32 API 调用被拒绝）。`n`n原因：通常是因为缺少管理员权限（UIPI 权限隔离）。`n请直接通过「复位窗口.vbs」运行以授予管理员权限！" "阴阳师窗口复位 - 错误" 16
} else {
    $posOk  = ($curL -eq $InitLeft) -and ($curT -eq $InitTop)
    $sizeOk = ($curW -eq $InitWidth) -and ($curH -eq $InitHeight)
    if (-not ($posOk -and $sizeOk)) {
        $detail = "复位未能完全匹配目标数值：`n`n实际生效：位置({0}, {1})  大小 {2} x {3}`n目标预设：位置({4}, {5})  大小 {6} x {7}`n`n提示：若尺寸有微小偏差，通常属于系统窗口边框阴影或游戏最小分辨率限制。" -f $curL, $curT, $curW, $curH, $InitLeft, $InitTop, $InitWidth, $InitHeight
        Show-Alert $detail "阴阳师窗口复位 - 提示" 48
    }
    # 若完全成功，保持完全静默，无需弹窗打扰
}

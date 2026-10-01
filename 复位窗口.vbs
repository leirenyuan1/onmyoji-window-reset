On Error Resume Next
Set objShell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")
strPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "reset_onmyoji.ps1")

If Not fso.FileExists(strPath) Then
    MsgBox "缺少核心脚本文件：reset_onmyoji.ps1" & vbCrLf & vbCrLf & "请确保【复位窗口.vbs】与【reset_onmyoji.ps1】存放在【同一个文件夹】内！", 16, "阴阳师窗口复位 - 文件缺失"
    WScript.Quit
End If

objShell.ShellExecute "powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPath & """", "", "runas", 0

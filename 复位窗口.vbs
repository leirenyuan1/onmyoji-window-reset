On Error Resume Next
Set objShell = CreateObject("Shell.Application")
Set fso = CreateObject("Scripting.FileSystemObject")
strPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "reset_onmyoji.ps1")

If Not fso.FileExists(strPath) Then
    MsgBox "Missing core script file: reset_onmyoji.ps1" & vbCrLf & vbCrLf & "Please make sure 'reset_onmyoji.ps1' is in the same folder as this script!", 16, "Onmyoji Window Reset"
    WScript.Quit
End If

objShell.ShellExecute "powershell.exe", "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPath & """", "", "runas", 0

Dim sh, scriptPath
Set sh = CreateObject("WScript.Shell")
scriptPath = Replace(WScript.ScriptFullName, "start_pomodoro.vbs", "pomodoro.ps1")
sh.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """", 0, False
Set sh = Nothing

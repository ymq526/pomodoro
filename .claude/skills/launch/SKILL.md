---
name: launch
description: Launch the Pomodoro app for manual testing. Use after editing pomodoro.ps1 to verify the GUI starts correctly.
disable-model-invocation: true
---

Launch the Pomodoro app using the VBScript wrapper:

```powershell
Start-Process wscript -ArgumentList "start_pomodoro.vbs"
```

Tell the user the app has been launched and to check the GUI looks correct. Remind them to close it before launching again to avoid duplicate instances.

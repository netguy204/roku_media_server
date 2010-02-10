rem Contributed by umbighouse
rem Copyright 2010

Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "springboard_debug.bat" & Chr(34), 0
Set WshShell = Nothing

TCPath=%Commander_path%
WinClose ahk_class TTOTAL_CMD
WinWaitClose

Loop
{
 FileDelete %TCPath%\tcmatch.dll
 if(!FileExist(TCPath . "\tcmatch.dll")) {
  break
 }
 Sleep,50
}

Loop
{
 FileDelete %TCPath%\tcmatch64.dll
 if(!FileExist(TCPath . "\tcmatch64.dll")) {
  break
 }
 Sleep,50
}

Loop
{
 FileDelete %TCPath%\tcmatch.exe
 if(!FileExist(TCPath . "\tcmatch.exe")) {
  break
 }
 Sleep,50
}

Loop
{
 FileDelete %TCPath%\tcmatch64.exe
 if(!FileExist(TCPath . "\tcmatch64.exe")) {
  break
 }
 Sleep,50
}

FileCopy %A_ScriptDir%\tcmatch.dll,%TCPath%\tcmatch.dll
FileCopy %A_ScriptDir%\tcmatch64.dll,%TCPath%\tcmatch64.dll
FileCopy %A_ScriptDir%\tcmatch.exe,%TCPath%\tcmatch.exe
FileCopy %A_ScriptDir%\tcmatch64.exe,%TCPath%\tcmatch64.exe
Run %TCPath%\totalcmd.exe,%TCPath%\
;Run %TCPath%\totalcmd64.exe,%TCPath%\

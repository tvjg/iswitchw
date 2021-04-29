;----------------------------------------------------------------------
;
; User configuration
;
#SingleInstance force
#NoTrayIcon
#Include lib\Accv2.ahk

; Use small icons in the listview
Global compact := true

; A bit of a hack, but this 'hides' the scorlls bars, rather the listview is
; sized out of bounds, you'll still be able to use the scroll wheel or arrows
; but when resizing the window you can't use the left edge of the window, just
; the top and bottom right.
Global hideScrollBars := true

; Uses tcmatch.dll included with QuickSearch eXtended by Samuel Plentz
; https://www.ghisler.ch/board/viewtopic.php?t=22592
; a bit slower, but supports Regex, Simularity, Srch & PinYin; use Winkey+/ to toggle it on/off
; while iswitch is running, included in lib folder, no license info that I could find
; see readme in lib folder for details, use the included tcmatch.ahk to change settings
; By default, for different search modes, start the string with:
;   ? - for regex
;   * - for srch
;   < - for simularity
useTCMatch := true

; Activate the window if it's the only match
activateOnlyMatch := false

; Hides the UI when focus is lost!
hideWhenFocusLost := false

; Window titles containing any of the listed substrings are filtered out from results
; useful for things like  hiding improperly configured tool windows or screen
; capture software during demos.
filters := []

; Add folders containing files or shortcuts you'd like to show in the list.
; Enter new paths as an array
; todo: show file extensions/path in the list, etc.
shortcutFolders := ["C:\Users\" A_UserName "\OneDrive\Desktop"
,"C:\Users\" A_UserName "\OneDrive\Documents"]

; Set this to true to update the list of windows every time the search is
; updated. This is usually not necessary and creates additional overhead, so
; it is disabled by default. 
refreshEveryKeystroke := false

; When true, filtered matches are scored and the best matches are presented
; first. This helps account for simple spelling mistakes such as transposed
; letters e.g. googel, vritualbox. When false, title matches are filtered and
; presented in the order given by Windows.
scoreMatches := true

; Split search string on spaces and use each term as an additional
; filter expression.
;
; For example, you are working on an AHK script:
;  - There are two Explorer windows open to ~/scripts and ~/scripts-old.
;  - Two Vim instances editing scripts in each one of those folders.
;  - A browser window open that mentions scripts in the title
;
; This is amongst all the other stuff going on. You bring up iswitchw and
; begin typing 'scrip'. Now, we have several best matches filtered.  But I
; want the Vim windows only. Now I might be able to make a more unique match by
; adding the extension of the file open in Vim: 'scripahk'. Pretty good, but
; really the first thought was process name -- Vim. By breaking on space, we
; can first filter the list for matches on 'scrip' for 'script' and then,
; 'vim' in order to match by Vim amongst the remaining windows.
useMultipleTerms := true

;----------------------------------------------------------------------
;
; Global variables
;
;     allwindows  - windows on desktop
;     windows     - windows in listbox
;     search      - the current search string
;     lastSearch  - previous search string
;     switcher_id - the window ID of the switcher window
;     compact     - true when compact listview is enabled (small icons)
;
;----------------------------------------------------------------------

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetBatchLines -1 ; faster execution
global switcher_id

; Load saved position from settings.ini
IniRead, x, settings.ini, position, x
IniRead, y, settings.ini, position, y
IniRead, w, settings.ini, position, w
IniRead, h, settings.ini, position, h
If (!x || !y || !w || !h || x = "ERROR" || y = "ERROR" || w = "ERROR" || h = "ERROR")
  x := y := w := h := 0 ; zero out of any values are invalid

OnMessage(0x201, "WM_LBUTTONDOWN") ; Allows clicking and dragging the window
;These remove the borders, while allowing the window to be resizable
;https://autohotkey.com/board/topic/23969-resizable-window-border/#entry155480
OnMessage(0x84, "WM_NCHITTEST")
OnMessage(0x83, "WM_NCCALCSIZE")
OnMessage(0x86, "WM_NCACTIVATE")

fileList := []
if IsObject(shortcutFolders) {
  for i, e in shortcutFolders
    Loop, Files, % e "\*"	
      fileList.Push({"fileName":RegExReplace(A_LoopFileName,"\.\w{3}$"),"path":A_LoopFileFullPath})
}

AutoTrim, off

Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow +Resize -DPIScale +MinSize220x127 +Hwndswitcher_id
Gui, Color, black, 191919
WinSet, Transparent, 225
Gui, Margin, 8, 10
Gui, Font, s14 cEEE8D5, Segoe MDL2 Assets
Gui, Add, Text,     xm+5 ym+3, % Chr(0xE721)
Gui, Font, s10 cEEE8D5, Segoe UI
Gui, Add, Edit,     w420 h25 x+10 ym gSearchChange vsearch -E0x200,
Gui, Add, ListView, % (hideScrollbars ? "x0" : "x9") " y+8 w490 h500 -VScroll -HScroll -Hdr -Multi Count10 AltSubmit vlist gListViewClick +LV0x10000 -E0x200", index|title|proc|tab
Gui, Show, % x ? "x" x " y" y " w" w " h" h : "" , Window Switcher
LV_ModifyCol(4,0)
WinHide, ahk_id %switcher_id%


; Add hotkeys for number row and pad, to focus corresponding item number in the list 
numkey := [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5", "Numpad6", "Numpad7", "Numpad8", "Numpad9", "Numpad0"]
for i, e in numkey {
    num := StrReplace(e, "Numpad")
    KeyFunc := Func("ActivateWindow").Bind(num = 0 ? 10 : num)
    Hotkey, IfWinActive, % "ahk_id" switcher_id
    Hotkey, % "#" e, % KeyFunc
}

; Define hotstrings for selecting rows, by typing the number with a space after
Loop 99 {
    KeyFunc := Func("ActivateWindow").Bind(A_Index)
    Hotkey, IfWinActive, % "ahk_id" switcher_id
    Hotstring(":X:" A_Index , KeyFunc)
}

Return

#'::
match := TCMatch("Feature request: Include browser tabs as | if they were windows · Issue #1 · tvjg\iswitchw","fea")
MsgBox, % match
Return


;----------------------------------------------------------------------
;
; Win+space to activate.
;
; #space::
CapsLock:: ; Use Shift+Capslock to toggle while in use by the hotkey
If WinActive("ahk_class Windows.UI.Core.CoreWindow") ; clear the search/start menu if it's open, otherwise it keeps stealing focus
  Send, {esc}
search := lastSearch := ""
allwindows := Object()
GuiControl, , Edit1
WinShow, ahk_id %switcher_id%
WinActivate, ahk_id %switcher_id%
WinGetPos, , , w, h, ahk_id %switcher_id%
WinSet, Region , 0-0 w%w% h%h% R15-15, ahk_id %switcher_id%
WinSet, AlwaysOnTop, On, ahk_id %switcher_id%
ControlFocus, Edit1, ahk_id %switcher_id%
If hideWhenFocusLost
  SetTimer, HideTimer, 10
Return

#/::
useTCMatch := !useTCMatch
ToolTip, % "TC Match: " (useTCMatch ? "On" : "Off")
SetTimer, tooltipOff, -2000
Return

tooltipOff:
  ToolTip
Return

#If WinActive("ahk_id" switcher_id)
Enter::       ;Activate window
Escape::      ;Close window
^Backspace::  ;Clear text
^w::          ; ''
^h::          ;Backspace
Down::        ;Next row
Tab::         ; ''
^k::          ; ''
Up::          ;Previous row
+Tab::        ; ''
^j::          ; ''
PgUp::        ;Jump up 4 rows
PgDn::        ;Jump down 4 rows
^Home::        ;Jump to top
^End::         ;Jump to bottom
!F4::         ;Quit
~Delete::
~Backspace::
  SetKeyDelay, -1
  Switch A_ThisHotkey {
    Case "Enter":       ActivateWindow()
    Case "Escape":      WinHide, ahk_id %switcher_id%
    Case "^Home":        LV_Modify(1, "Select Focus Vis")
    Case "^End":         LV_Modify(LV_GetCount(), "Select Focus Vis")
    Case "!F4":         Quit()
    Case "^h":          ControlSend, Edit1, {Backspace}, ahk_id %switcher_id%
    Case "~Delete", "~Backspace", "^Backspace", "^w":
      If ( (windows.MaxIndex() < 1 && LV_GetCount() > 1) || LV_GetCount() = 1)
        GuiControl, , Edit1,
      Else If (A_ThisHotkey = "^Backspace" || A_ThisHotkey = "^w")
        ControlSend, Edit1, ^+{left}{Backspace}, ahk_id %switcher_id%
    Case "Tab", "+Tab", "Up", "Down", "PgUp", "PgDn", "^k", "^j":
      page := InStr(A_ThisHotkey,"Pg")
      row := LV_GetNext()
      jump := page ? 4 : 1
      If (row = 0)
        row := 1
      row := GetKeyState("Shift") || InStr(A_ThisHotkey,"Up") || InStr(A_ThisHotkey,"^k") ? row - jump : row + jump
      If (row > LV_GetCount())
        row := page ? LV_GetCount() : 1
      Else If (row < 1)
        row := page ? 1 : LV_GetCount()
      LV_Modify(row, "Select Focus Vis")
  }
Return

; Resizes the search field and list to the GUI width
GuiSize:
  GuiControl, Move, list, % "w" (hideScrollBars ? A_GuiWidth + 20 : A_GuiWidth - 20) " h" A_GuiHeight - 50
  GuiControl, Move, search, % "w" A_GuiWidth - 52
  LV_ModifyCol(3
  , A_GuiWidth - ( hideScrollBars
  ? (compact ? 170 : 190)   ; Resizes column 3 to match gui width
  : (compact ? 200 : 220)))
  WinGetPos, x, y, w, h, % "ahk_id" switcher_id
  WinSet, Region , 0-0 w%w% h%h% R15-15, % "ahk_id" switcher_id  ;Sets window region to round off corners
  SetTimer, SaveTimer, -2000
Return

SaveTimer:
  WinGetPos, x, y, w, h, % "ahk_id" switcher_id
  IniWrite, % x, settings.ini, position, x
  IniWrite, % y, settings.ini, position, y
  IniWrite, % w - 14, settings.ini, position, w ; manual adjustment of saved w/h. Gui, Show always 
  IniWrite, % h - 14, settings.ini, position, h ; makes it 14px larger when specifying coords.
Return

; Hides the UI if it loses focus
HideTimer:
  If !WinActive("ahk_id" switcher_id) {
    WinHide, ahk_id %switcher_id%
    SetTimer, HideTimer, Off
  }
Return

Quit() {
  global switcher_id
  Gosub, SaveTimer
  ExitApp 
}


;----------------------------------------------------------------------
;
; Runs whenever Edit control is updated
SearchChange:
  Settimer, Refresh, -1
Return

Refresh:
  if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  Gui, Submit, NoHide
  StartTime := A_TickCount
  If useTCMatch
    RefreshWindowList()
  Else
    RefreshWindowListOld()
  ElapsedTime := A_TickCount - StartTime
  If (LV_GetCount() > 1) {
    Gui, Font, % LV_GetCount() > 1 && windows.MaxIndex() < 1 ? "cff2626" : "cEEE8D5"
    GuiControl, Font, Edit1
  } Else if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  For i, e in windows {
    str .= Format("{:-4} {:-15} {:-55}Score: {}`n",A_Index ":",SubStr(e.procName,1,14),StrLen(e.title) > 50 ? SubStr(e.title,1,50) "..." : e.title,e.score)
  }
  if search
  OutputDebug, % "lvcount: " LV_GetCount() " - windows: " windows.MaxIndex()
  . "`n------------------------------------------------------------------------------------------------" 
  . Format("`nNew filter: {} | Result count: {:-4} | Time: {:-4} | Search string: {} ",toggleMethod ? "On " : "Off",LV_GetCount(),ElapsedTime,search)
  . "`n------------------------------------------------------------------------------------------------`n" . str
  str := ""
  return

;----------------------------------------------------------------------
;
; Handle mouse click events on the listview
;
ListViewClick:
  if (A_GuiControlEvent = "Normal") {
    ActivateWindow()
  }
  return

;----------------------------------------------------------------------
;
; Unoptimized array search, returns index of first occurrence or -1
;
IncludedIn(haystack,needle)
{
  Loop % haystack.MaxIndex()
  {
    item := haystack[a_index]
    StringTrimRight, item, item, 0
    if item =
      continue

    IfInString, needle, %item%
      return %a_index%
  }

  return -1
}

;----------------------------------------------------------------------
;
; Fetch info on all active windows
;
GetAllWindows()
{
  global switcher_id, filters, ChromeInst, Chromes
  windows := Object()

  top := DllCall("GetTopWindow", "Ptr","")
  Loop {
  	next :=	DllCall("GetWindow", "Ptr", (A_Index = 1 ? top : next),"uint",2)
  	WinGetTitle, title, % "ahk_id" next
    if IncludedIn(filters, title) > -1
      continue
  	if title {
      procName := GetProcessName(next)
      if (procName = "chrome") {
        tabs := StrSplit(JEE_ChromeGetTabNames(next),"`n")
        for i, e in tabs {
          if (!e || e ~= "i)group.*and \d+ other tabs") ; remove blank titles that appears when there are grouped tabs
            continue
          if RegExMatch(e, "i)(.*) - Part of group (.*)", match) ; appends group name to grouped tabs
            e := match2 " " Chr(0x2022) " " match1
          windows.Push({"id":next, "title": e, "procName": "Chrome tab", "num": i})
        }
      } else if (procName = "firefox") {
        tabs := StrSplit(JEE_FirefoxGetTabNames(next),"`n")
        for i, e in tabs
          windows.Push({"id":next, "title": e, "procName": "Firefox tab", "num": i})
      } else if (procName = "vivaldi") {
        tabs := StrSplit(VivaldiGetTabNames(next),"`n")
        for i, e in tabs {
          tab := StrSplit(e, "¥")
          if !tab.1
            continue
          windows.Push({"id":next, "title": tab.1, "procName": "Vivaldi tab", "num": tab.2, "row": tab.3})
        }
      } Else {
        windows.Push({ "id": next, "title": title, "procName": procName })
      }
  	}
  } Until (!next)

  return windows
}

RefreshWindowList() {
  global allwindows, windows, scoreMatches, fileList
  global search, lastSearch, refreshEveryKeystroke
  if (search ~= "^\d+")
    return  
  windows := []
  toRemove := ""
  If (!search || refreshEvery`Keystroke) {
    allwindows := GetAllWindows()
    for _, e in fileList {
      path := e.path 
      SplitPath, path, OutFileName, OutDir, OutExt, OutNameNoExt, OutDrive
      RegExMatch(OutDir, "\\(\w+)$", folder)
      allwindows.Push({"procname":folder1,"title":e.fileName . (!RegExMatch(OutExt,"txt|lnk") ? "." OutExt : "" ),"path":e.path})
    }
  }
  for i, e in allwindows {
    str := e.procName " " e.title
    if !search || TCMatch(str,search) {
      If scoreMatches
        e.score := FuzzySearch(search, str)
      windows.Push(e)
    } else {
      toRemove .= i ","
    }
  }
  If scoreMatches
    windows := objectSort(windows, "score")
  OutputDebug, % "Allwindows count: " allwindows.MaxIndex() " | windows count: " windows.MaxIndex() "`n"
  DrawListView(windows)
  for i, e in StrSplit(toRemove,",")
    allwindows.Delete(e)
}

/* ObjectSort() by bichlepa
* 
* Description:
*    Reads content of an object and returns a sorted array
* 
* Parameters:
*    obj:              Object which will be sorted
*    keyName:          [optional] 
*                      Omit it if you want to sort a array of strings, numbers etc.
*                      If you have an array of objects, specify here the key by which contents the object will be sorted.
*    callBackFunction: [optional] Use it if you want to have custom sort rules.
*                      The function will be called once for each value. It must return a number or string.
*    reverse:          [optional] Pass true if the result array should be reversed
*/

objectSort(obj, keyName="", callbackFunc="", reverse=false)
{
    temp := Object()
    sorted := Object() ;Return value

    for oneKey, oneValue in obj
    {
        ;Get the value by which it will be sorted
        if keyname
            value := oneValue[keyName]
        else
            value := oneValue

        ;If there is a callback function, call it. The value is the key of the temporary list.
        if (callbackFunc)
            tempKey := %callbackFunc%(value)
        else
            tempKey := value

        ;Insert the value in the temporary object.
        ;It may happen that some values are equal therefore we put the values in an array.
        if not isObject(temp[tempKey])
            temp[tempKey] := []
        temp[tempKey].push(oneValue)
    }

    ;Now loop throuth the temporary list. AutoHotkey sorts them for us.
    for oneTempKey, oneValueList in temp
    {
        for oneValueIndex, oneValue in oneValueList
        {
            ;And add the values to the result list
            if (reverse)
                sorted.insertAt(1,oneValue)
            else
                sorted.push(oneValue)
        }
    }

    return sorted
}

;----------------------------------------------------------------------
;
; Refresh the list of windows according to the search criteria
;
RefreshWindowListOld()
{
  global allwindows, windows
  global search, lastSearch, refreshEveryKeystroke
  if (search ~= "^\d+")
    return
  uninitialized := (allwindows.MinIndex() = "")

  if (uninitialized || refreshEveryKeystroke)
    allwindows := GetAllWindows()

  currentSearch := Trim(search)
  if ((currentSearch == lastSearch) && !uninitialized) {
    return
  }

  ; When adding to criteria (ie typing, not erasing), refilter
  ; the existing filtered list. This should be sane since the even if we enter
  ; a new letter at the beginning of the search term, all shown matches should
  ; still contain the previous search term as a 'substring'.
  useExisting := (StrLen(currentSearch) > StrLen(lastSearch))
  lastSearch := currentSearch

  windows := FilterWindowList(useExisting ? windows : allwindows, currentSearch)

  DrawListView(windows)
}

;----------------------------------------------------------------------
;
; Filter window list with given search criteria
;
FilterWindowList(list, criteria)
{
  global scoreMatches, useMultipleTerms
  filteredList := Object(), expressions := Object()
  lastTermInSearch := criteria, doScore := scoreMatches

  ; If useMultipleTerms, do multiple passes with filter expressions
  if (useMultipleTerms) {
    StringSplit, searchTerms, criteria, %A_space%

    Loop, %searchTerms0%
    {
      term := searchTerms%A_index%
      lastTermInSearch := term

      expr := BuildFilterExpression(term)
      expressions.Insert(expr)
    }
  } else if (criteria <> "") {
    expr := BuildFilterExpression(criteria)
    expressions[0] := expr
  }

  atNextWindow:
  For idx, window in list
  {
    ; if there is a search string
    if criteria <>
    {
      title := window.title
      procName := window.procName

      ; don't add the windows not matching the search string
      titleAndProcName = %procName% %title%

      For idx, expr in expressions
      {
        if RegExMatch(titleAndProcName, expr) = 0
          continue atNextWindow
      }
    }

    doScore := scoreMatches && (criteria <> "") && (lastTermInSearch <> "")
    window["score"] := doScore ? FuzzySearch(lastTermInSearch, titleAndProcName) : 0

    filteredList.Insert(window)
  }
  
  return (doScore ? SortByScore(filteredList) : filteredList)
}
;----------------------------------------------------------------------
;
; http://stackoverflow.com/questions/2891514/algorithms-for-fuzzy-matching-strings
;
; Matching in the style of Ido/CtrlP
;
; Returns:
;   Regex for provided search term 
;
; Example:
;   explr builds the regex /[^e]*e[^x]*x[^p]*p[^l]*l[^r]*r/i
;   which would match explorer
;   or likewise
;   explr ahk
;   which would match Explorer - ~/autohotkey, but not Explorer - Documents
;
; Rules:
;  It is expected that all the letters of the input be in the keyword
;  It is expected that the letters in the input be in the same order in the keyword
;  The list of keywords returned should be presented in a consistent (reproductible) order
;  The algorithm should be case insensitive
;

BuildFilterExpression(term) {
  expr := "i)"
  for _, character in StrSplit(term)
    expr .= "[^" . character . "]*" . character
  return expr
}

;------------------------------------------------------------------------
;
; Perform insertion sort on list, comparing on each item's score property 
;
SortByScore(list)
{
  Loop % list.MaxIndex() - 1
  {
    i := A_Index+1
    window := list[i]
    j := i-1

    While j >= 0 and list[j].score > window.score
    {
      list[j+1] := list[j]
      j--
    }

    list[j+1] := window
  }

return list
}

;----------------------------------------------------------------------
;
; Activate selected window
;
ActivateWindow(rowNum := "")
{
  global windows, ChromeInst

  If !rowNum  
    rowNum:= LV_GetNext(0)
  If (rowNum > LV_GetCount())
    return
  LV_GetText(title, rowNum, 3)
  LV_GetText(tab, rowNum, 4)
  Gui Submit
  window := windows[rowNum]
  wid := window.id
  procName := window.procName
  url := window.url
  num := window.num
  path := window.path
  ; In some cases, calling WinMinimize minimizes the window, but it retains its
  ; focus preventing WinActivate from raising window.
  If window.HasKey("path") {
    ; SplitPath, path, , OutDir
    Run, % """" path """" ;, % OutDir
  } Else {
    If (procName = "Chrome tab")
      JEE_ChromeFocusTabByNum(wid,num)
    Else If (procName = "Firefox tab")
      JEE_FirefoxFocusTabByNum(wid,num)
    Else If (procName = "Vivaldi tab")
      VivaldiFocusTabByNum(wid,num,window.row)
    IfWinActive, ahk_id %wid%
    {
      WinGet, state, MinMax, ahk_id %wid%
      if (state = -1)
      {
        WinRestore, ahk_id %wid%
      }
    } else {
      WinActivate, ahk_id %wid%
    }
  }
  LV_Delete()
}

;----------------------------------------------------------------------
;
; Add window list to listview
;
DrawListView(windows)
{
  Global switcher_id, fileList
  static IconArray
  If !IsObject(IconArray)
    IconArray := {}
  windowCount := windows.MaxIndex()
  If !windowCount
    return
  imageListID := IL_Create(windowCount, 1, compact ? 0 : 1)

  ; Attach the ImageLists to the ListView so that it can later display the icons:
  LV_SetImageList(imageListID, 1)
  LV_Delete()
  iconCount = 0
  removedRows := Array()
  For idx, window in windows
  {
    wid := window.id
    title := window.title
    procName := window.procName
    tab := window.num

    ; Retrieves an 8-digit hexadecimal number representing extended style of a window.
    WinGet, style, ExStyle, ahk_id %wid%
    ; http://msdn.microsoft.com/en-us/library/windows/desktop/ff700543(v=vs.85).aspx
    ; Forces a top-level window onto the taskbar when the window is visible.
    WS_EX_APPWINDOW = 0x40000
    ; A tool window does not appear in the taskbar or in the dialog that appears when the user presses ALT+TAB.
    WS_EX_TOOLWINDOW = 0x80

    isAppWindow := (style & WS_EX_APPWINDOW)
    isToolWindow := (style & WS_EX_TOOLWINDOW)

    ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms632599(v=vs.85).aspx#owned_windows
    ; An application can use the GetWindow function with the GW_OWNER flag to retrieve a handle to a window's owner.
    GW_OWNER = 4
    ownerHwnd := DllCall("GetWindow", "uint", wid, "uint", GW_OWNER)
    iconNumber := ""
    if window.HasKey("path") {
      FileName := window.path
      ; Calculate buffer size required for SHFILEINFO structure.
      sfi_size := A_PtrSize + 8 + (A_IsUnicode ? 680 : 340)
      VarSetCapacity(sfi, sfi_size)
      SplitPath, FileName,,, FileExt  ; Get the file's extension.
      for i, e in fileList {
        if (e.path = window.path) {
          fileObj := fileList[i]
          iconHandle := fileObj.icon
          Break
        }
      }
      If !iconHandle {
        if !DllCall("Shell32\SHGetFileInfo" . (A_IsUnicode ? "W":"A"), "Str", FileName
        , "UInt", 0, "Ptr", &sfi, "UInt", sfi_size, "UInt", 0x101) { ; 0x101 is SHGFI_ICON+SHGFI_SMALLICON
          IconNumber := 9999999  ; Set it out of bounds to display a blank icon.
        } else {
          iconHandle := NumGet(sfi, 0)
          fileObj.icon := iconHandle
        }
      }
      if (iconHandle <> 0)
        iconNumber := DllCall("ImageList_ReplaceIcon", UInt, imageListID, Int, -1, UInt, iconHandle) + 1
    } else if (procName ~= "(Chrome|Firefox|Vivaldi) tab" || isAppWindow || ( !ownerHwnd and !isToolWindow )) {
      if !(iconHandle := window.icon) {
        if (procName = "Chrome tab") ; Apply the Chrome icon to found Chrome tabs
          wid := WinExist("ahk_exe chrome.exe")
        else if (procName = "Firefox tab")
          wid := WinExist("ahk_exe firefox.exe")
        else if (procName = "Vivaldi tab")
          wid := WinExist("ahk_exe vivaldi.exe")
        ; http://www.autohotkey.com/docs/misc/SendMessageList.htm
        WM_GETICON := 0x7F

        ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms632625(v=vs.85).aspx
        ICON_BIG := 1
        ICON_SMALL2 := 2
        ICON_SMALL := 0

        SendMessage, WM_GETICON, ICON_BIG, 0, , ahk_id %wid%
        iconHandle := ErrorLevel

        if (iconHandle = 0)
        {
          SendMessage, WM_GETICON, ICON_SMALL2, 0, , ahk_id %wid%
          iconHandle := ErrorLevel

          if (iconHandle = 0)
          {
            SendMessage, WM_GETICON, ICON_SMALL, 0, , ahk_id %wid%
            iconHandle := ErrorLevel

            if (iconHandle = 0)
            {
              ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms633581(v=vs.85).aspx
              ; To write code that is compatible with both 32-bit and 64-bit
              ; versions of Windows, use GetClassLongPtr. When compiling for 32-bit
              ; Windows, GetClassLongPtr is defined as a call to the GetClassLong
              ; function.
              iconHandle := DllCall("GetClassLongPtr", "uint", wid, "int", -14) ; GCL_HICON is -14

              if (iconHandle = 0)
              {
                iconHandle := DllCall("GetClassLongPtr", "uint", wid, "int", -34) ; GCL_HICONSM is -34

                if (iconHandle = 0) {
                  iconHandle := DllCall("LoadIcon", "uint", 0, "uint", 32512) ; IDI_APPLICATION is 32512
                }
              }
            }
          }
        }
      }
      if (iconHandle <> 0) {
        iconNumber := DllCall("ImageList_ReplaceIcon", UInt, imageListID, Int, -1, UInt, iconHandle) + 1
        window.icon := iconHandle
      }

    } else {
      WinGetClass, Win_Class, ahk_id %wid%
      if Win_Class = #32770 ; fix for displaying control panel related windows (dialog class) that aren't on taskbar
        iconNumber := IL_Add(imageListID, "C:\WINDOWS\system32\shell32.dll", 217) ; generic control panel icon
    }

    if (iconNumber < 1) {
      removedRows.Insert(idx)
    } else {
      iconCount+=1
      LV_Add("Icon" . iconNumber, iconCount, window.procName, title, tab)
    }
  }

  ; Don't draw rows without icons.
  windowCount-=removedRows.MaxIndex()
  For key,rowNum in removedRows
  {
    windows.RemoveAt(rowNum)
  }

  LV_Modify(1, "Select Focus")

  LV_ModifyCol(1,compact ? 50 : 70)
  LV_ModifyCol(2,110)
  If (windows.Count() = 1 && activateOnlyMatch)
    ActivateWindow(1)
}

;----------------------------------------------------------------------
;
; Get process name for given window id
;
GetProcessName(wid)
{
  WinGet, name, ProcessName, ahk_id %wid%
  StringGetPos, pos, name, .
  if ErrorLevel <> 1
  {
    StringLeft, name, name, %pos%
  }

  return name
}

; Wrapper for Strdiff, returns better results, found somewhere on the forum, can't recall where though
FuzzySearch(string1, string2)
{
	lenl := StrLen(string1)
	lens := StrLen(string2)
	if(lenl > lens)
	{
		shorter := string2
		longer := string1
	}
	else if(lens > lenl)
	{
		shorter := string1
		longer := string2
		lens := lenl
		lenl := StrLen(string2)
	}
	else
		return StrDiff(string1, string2)
	min := 1
	Loop % lenl - lens + 1
	{
		distance := StrDiff(shorter, SubStr(longer, A_Index, lens))
		if(distance < min)
			min := distance
	}
	return min
}


/*
https://gist.github.com/grey-code/5286786

By Toralf:
Forum thread: http://www.autohotkey.com/board/topic/54987-sift3-super-fast-and-accurate-string-distance-algorithm/#entry345400

Basic idea for SIFT3 code by Siderite Zackwehdex
http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html

Took idea to normalize it to longest string from Brad Wood
http://www.bradwood.com/string_compare/

Own work:
- when character only differ in case, LSC is a 0.8 match for this character
- modified code for speed, might lead to different results compared to original code
- optimized for speed (30% faster then original SIFT3 and 13.3 times faster than basic Levenshtein distance)
*/

;----------------------------------------------------------------------
;
; returns a float: between "0.0 = identical" and "1.0 = nothing in common"
;
StrDiff(str1, str2, maxOffset:=5) {
  if (str1 = str2)
    return (str1 == str2 ? 0/1 : 0.2/StrLen(str1))

  if (str1 = "" || str2 = "")
    return (str1 = str2 ? 0/1 : 1/1)

  StringSplit, n, str1
  StringSplit, m, str2

  ni := 1, mi := 1, lcs := 0
  while ((ni <= n0) && (mi <= m0)) {
    if (n%ni% == m%mi%)
      lcs++
    else if (n%ni% = m%mi%)
      lcs += 0.8
    else {
      Loop, % maxOffset {
        oi := ni + A_Index, pi := mi + A_Index
        if ((n%oi% = m%mi%) && (oi <= n0)) {
          ni := oi, lcs += (n%oi% == m%mi% ? 1 : 0.8)
          break
        }
        if ((n%ni% = m%pi%) && (pi <= m0)) {
          mi := pi, lcs += (n%ni% == m%pi% ? 1 : 0.8)
          break
        }
      }
    }

    ni++, mi++
  }

  return ((n0 + m0)/2 - lcs) / (n0 > m0 ? n0 : m0)
}

; Allows dragging the window position
WM_LBUTTONDOWN() {
    If A_Gui
        PostMessage, 0xA1, 2 ; 0xA1 = WM_NCLBUTTONDOWN 
}

; Sizes the client area to fill the entire window.
WM_NCCALCSIZE()
{
  If A_Gui
    return 0
}

; Prevents a border from being drawn when the window is activated.
WM_NCACTIVATE()
{
  If A_Gui
    return 1
}

; Redefine where the sizing borders are.  This is necessary since
; returning 0 for WM_NCCALCSIZE effectively gives borders zero size.
WM_NCHITTEST(wParam, lParam)
{
    static border_size = 6

    if !A_Gui
        return

    WinGetPos, gX, gY, gW, gH
    x := lParam<<48>>48, y := lParam<<32>>48

    hit_left := x < gX+border_size
    hit_right := x >= gX+gW-border_size
    hit_top := y < gY+border_size
    hit_bottom := y >= gY+gH-border_size

    if hit_top
    {
        if hit_left
            return 0xD
        else if hit_right
            return 0xE
        else
            return 0xC
    }
    else if hit_bottom
    {
        if hit_left
            return 0x10
        else if hit_right
            return 0x11
        else
            return 0xF
    }
    else if hit_left
        return 0xA
    else if hit_right
        return 0xB

    ; else let default hit-testing be done
}

; Needs improvement, can currently only get tab names for stacked tab groups if they're visible/expanded
VivaldiGetTabNames(hwnd) {
    ; oAcc := Acc_Get("Object", "4.1.2.1.1.1.1.1.1.2", 0, "ahk_exe vivaldi.exe")
    oAcc := Acc_Get("Object", "4.1.2.1.1.1.1.1.1.2.1.1.1", 0, "ahk_id" hwnd)
    oAcc2 := Acc_Get("Object", "4.1.2.1.1.1.1.1.1.2.2.1", 0, "ahk_id" hwnd)
	vRet := 0
	Loop 2 {
    row++
    i := ""
    	oChildren := Acc_Children(A_Index = 1 ? oAcc : oAcc2)
		for _, oChild in oChildren
		{
    	    oGrandchild := Acc_Children(oChild)[1]
			if (oGrandchild.accRole(0) = 20 && name := oGrandchild.accName(0) )
			{
				i++
    	        str .= name "¥" i "¥" row "`n"
			}
		}
	}
    return str
}

VivaldiFocusTabByNum(hWnd:="", vNum:="", row := "")
{
	local
	if !vNum
		return
	if (hWnd = "")
		hWnd := WinExist("A")
  if (row = 1) {
    tabRow := Acc_Get("Object", "4.1.2.1.1.1.1.1.1.2.1.1.1", 0, "ahk_id" hwnd)
    Acc_Children(tabRow)[vNum].accDoDefaultAction(0)
  } else if (row = 2) {
    tabRow2 := Acc_Get("Object", "4.1.2.1.1.1.1.1.1.2.2.1", 0, "ahk_id" hwnd)
    Acc_Children(tabRow2)[vNum].accDoDefaultAction(0)
  } else {
    vNum := ""
  }
	return vNum
}

;==================================================

;Chrome functions suite (tested on Chrome v77):

;requires Acc.ahk:
;Acc library (MSAA) and AccViewer download links - AutoHotkey Community
;https://autohotkey.com/boards/viewtopic.php?f=6&t=26201

;JEE_ChromeAccInit(vValue)
;JEE_ChromeGetUrl(hWnd:="", vOpt:="")
;JEE_ChromeGetTabCount(hWnd:="")
;JEE_ChromeGetTabNames(hWnd:="", vSep:="`n")
;JEE_ChromeFocusTabByNum(hWnd:="", vNum:="")
;JEE_ChromeFocusTabByName(hWnd:="", vTitle:="", vNum:="")
;JEE_ChromeGetFocusedTabNum(hWnd:="")
;JEE_ChromeAddressBarIsFoc(hWnd:="")
;JEE_ChromeCloseOtherTabs(hWnd:="", vOpt:="", vNum:="")

;note: you can only get the url for the *active* tab via Acc,
;to get the urls for other tabs, you could use a browser extension, see:
;Firefox/Chrome: copy titles/urls to the clipboard - AutoHotkey Community
;https://autohotkey.com/boards/viewtopic.php?f=22&t=66246

;==================================================

;note: these Acc paths often change:
;Acc paths determined via:
;[JEE_AccGetTextAll function]
;Acc: get text from all window/control elements - AutoHotkey Community
;https://autohotkey.com/boards/viewtopic.php?f=6&t=40615

JEE_ChromeAccInit(vValue)
{
	if (vValue = "U1")
		return "4.1.2.1.2.5.2" ;address bar
	if (vValue = "U2")
		return "4.1.2.2.2.5.2" ;address bar
	if (vValue = "T")
		return "4.1.2.1.1.1" ;tabs (append '.1' to get the first tab)
}

;==================================================

JEE_ChromeGetUrl(hWnd:="", vOpt:="")
{
	local
	static vAccPath1 := JEE_ChromeAccInit("U1")
	static vAccPath2 := JEE_ChromeAccInit("U2")
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", vAccPath1, 0, "ahk_id " hWnd)
	if !IsObject(oAcc)
	|| !(oAcc.accName(0) = "Address and search bar")
		oAcc := Acc_Get("Object", vAccPath2, 0, "ahk_id " hWnd)
	vUrl := oAcc.accValue(0)
	oAcc := ""

	if InStr(vOpt, "x")
	{
		if !(vUrl = "") && !InStr(vUrl, "://")
			vUrl := "http://" vUrl
	}
	return vUrl
}

;==================================================

JEE_ChromeGetTabCount(hWnd:="")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
	vCount := 0
	for _, oChild in Acc_Children(oAcc)
	{
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		if (oChild.accRole(0) = 0x2B)
			continue
		vCount++
	}
	oAcc := oChild := ""
	return vCount
}

;==================================================

JEE_ChromeGetTabNames(hWnd:="", vSep:="`n")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)

	vHasSep := !(vSep = "")
	if vHasSep
		vOutput := ""
	else
		oOutput := []
	for _, oChild in Acc_Children(oAcc)
	{
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		if (oChild.accRole(0) = 0x2B)
			continue
		try vTabText := oChild.accName(0)
		catch
			vTabText := ""
		if vHasSep
			vOutput .= vTabText vSep
		else
			oOutput.Push(vTabText)
	}
	oAcc := oChild := ""
	return vHasSep ? SubStr(vOutput, 1, -StrLen(vSep)) : oOutput
}

;==================================================

JEE_ChromeFocusTabByNum(hWnd:="", vNum:="")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	if !vNum
		return
	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
	if !Acc_Children(oAcc)[vNum]
		vNum := ""
	else
		Acc_Children(oAcc)[vNum].accDoDefaultAction(0)
	oAcc := ""
	return vNum
}

;==================================================

JEE_ChromeFocusTabByName(hWnd:="", vTitle:="", vNum:="")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	if (vNum = "")
		vNum := 1
	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
	vCount := 0, vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		vTabText := oChild.accName(0)
		if (vTabText = vTitle)
			vCount++
		if (vCount = vNum)
		{
			oChild.accDoDefaultAction(0), vRet := A_Index
			break
		}
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

JEE_ChromeGetFocusedTabNum(hWnd:="")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		;STATE_SYSTEM_SELECTED := 0x2
		if (oChild.accState(0) & 0x2)
		{
			vRet := A_Index
			break
		}
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

JEE_ChromeAddressBarIsFoc(hWnd:="")
{
	local
	static vAccPath1 := JEE_ChromeAccInit("U1")
	static vAccPath2 := JEE_ChromeAccInit("U2")
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", vAccPath1, 0, "ahk_id " hWnd)
	if !IsObject(oAcc)
	|| !(oAcc.accName(0) = "Address and search bar")
		oAcc := Acc_Get("Object", vAccPath2, 0, "ahk_id " hWnd)
	;STATE_SYSTEM_FOCUSED := 0x4
	vIsFoc := !!(oAcc.accState(0) & 0x4)
	oAcc := ""
	return vIsFoc
}

;==================================================

;vOpt: L (close tabs to the left)
;vOpt: R (close tabs to the right)
;vOpt: LR (close other tabs)
;vOpt: (blank) (close other tabs)
;vNum: specify a tab other than the focused tab
JEE_ChromeCloseOtherTabs(hWnd:="", vOpt:="", vNum:="")
{
	local
	static vAccPath := JEE_ChromeAccInit("T")
	if (hWnd = "")
		hWnd := WinExist("A")
	if (vNum = "")
		vNum := JEE_ChromeGetFocusedTabNum(hWnd)
	if (vOpt = "")
		vOpt := "LR"
	vDoCloseLeft := !!InStr(vOpt, "L")
	vDoCloseRight := !!InStr(vOpt, "R")

	oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
	vRet := 0
	oChildren := Acc_Children(oAcc)
	vIndex := oChildren.Length() + 1
	Loop % vIndex - 1
	{
		vIndex--
		oChild := oChildren[vIndex]
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		if (oChild.accRole(0) = 0x2B)
			continue
		if (vIndex = vNum)
			continue
		if (vIndex > vNum) && !vDoCloseRight
			continue
		if (vIndex < vNum) && !vDoCloseLeft
			continue
		oChild2 := Acc_Children(oChild).4
		if (oChild2.accName(0) = "Close")
			oChild2.accDoDefaultAction(0)
		oChild2 := ""
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

;Firefox functions suite (tested on Firefox v69):

;requires Acc.ahk:
;Acc library (MSAA) and AccViewer download links - AutoHotkey Community
;https://autohotkey.com/boards/viewtopic.php?f=6&t=26201

;JEE_FirefoxAccInit(vValue)
;JEE_FirefoxGetUrl(hWnd:="", vOpt:="")
;JEE_FirefoxGetTabCount(hWnd:="")
;JEE_FirefoxGetTabNames(hWnd:="", vSep:="`n")
;JEE_FirefoxFocusTabByNum(hWnd:="", vNum:="")
;JEE_FirefoxFocusTabByName(hWnd:="", vTitle:="", vNum:="")
;JEE_FirefoxGetFocusedTabNum(hWnd:="")
;JEE_FirefoxAddressBarIsFoc(hWnd:="")
;JEE_FirefoxCloseOtherTabs(hWnd:="", vOpt:="", vNum:="")

;warning: JEE_FirefoxCloseOtherTabs:
;there is no separate Close button Acc element to do accDoDefaultAction on,
;so at present, each tab is focused, and Ctrl+W is sent to it, which is unreliable

;note: you can only get the url for the *active* tab via Acc,
;to get the urls for other tabs, you could use a browser extension, see:
;Firefox/Chrome: copy titles/urls to the clipboard - AutoHotkey Community
;https://autohotkey.com/boards/viewtopic.php?f=22&t=66246

;==================================================

;note: this function is redundant
;note: an equivalent function is needed for Chrome
JEE_FirefoxAccInit(vValue)
{
	local
}

;==================================================

JEE_FirefoxGetUrl(hWnd:="", vOpt:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	Loop 10
	{
		vIndex := A_Index
		vAccPath := "application.tool_bar3.combo_box1.editable_text"
		;vAccPath := "4.25.3.2"
		if InStr(vOpt, "p") ;(pop-up window)
			vAccPath := "application.tool_bar1.combo_box1.editable_text"
		oAcc := Acc_Get("Object", vAccPath, 0, "ahk_id " hWnd)
		if !ErrorLevel
			break
		;Sleep(100)
		DllCall("kernel32\Sleep", "UInt",100)
	}
	if (vIndex = 10)
		return

	vUrl := ""
	try vUrl := oAcc.accValue(0)
	oAcc := ""

	if InStr(vOpt, "x")
	{
		if !(vUrl = "") && !InStr(vUrl, "://")
			vUrl := "http://" vUrl
	}
	return vUrl
}

;==================================================

JEE_FirefoxGetTabCount(hWnd:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	vCount := 0
	for _, oChild in Acc_Children(oAcc)
	{
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		if (oChild.accRole(0) = 0x2B)
			continue
		vCount++
	}
	oAcc := oChild := ""
	return vCount
}

;==================================================

JEE_FirefoxGetTabNames(hWnd:="", vSep:="`n")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	vHasSep := !(vSep = "")
	if vHasSep
		vOutput := ""
	else
		oOutput := []
	for _, oChild in Acc_Children(oAcc)
	{
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		if (oChild.accRole(0) = 0x2B)
			continue
		try vTabText := oChild.accName(0)
		catch
			vTabText := ""
		if vHasSep
			vOutput .= vTabText vSep
		else
			oOutput.Push(vTabText)
	}
	oAcc := oChild := ""
	return vHasSep ? SubStr(vOutput, 1, -StrLen(vSep)) : oOutput
}

;==================================================

JEE_FirefoxFocusTabByNum(hWnd:="", vNum:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	if !vNum
		return
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet || !Acc_Children(oAcc)[vNum]
		vNum := ""
	else
		Acc_Children(oAcc)[vNum].accDoDefaultAction(0)
	oAcc := oChild := ""
	return vNum
}

;==================================================

JEE_FirefoxFocusTabByName(hWnd:="", vTitle:="", vNum:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	if (vNum = "")
		vNum := 1
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	vCount := 0, vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		vTabText := oChild.accName(0)
		if (vTabText = vTitle)
			vCount++
		if (vCount = vNum)
		{
			oChild.accDoDefaultAction(0), vRet := A_Index
			break
		}
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

JEE_FirefoxGetFocusedTabNum(hWnd:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		;STATE_SYSTEM_SELECTED := 0x2
		if (oChild.accState(0) & 0x2)
		{
			vRet := A_Index
			break
		}
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

JEE_FirefoxAddressBarIsFoc(hWnd:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Navigation Toolbar")
			oAcc := oChild, vRet := 1
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	oAcc := Acc_Children(oAcc).6
	oAcc := Acc_Children(oAcc).2
	;STATE_SYSTEM_FOCUSED := 0x4
	vIsFoc := !!(oAcc.accState(0) & 0x4)
	oAcc := oChild := ""
	return vIsFoc
}

;==================================================

;vOpt: L (close tabs to the left)
;vOpt: R (close tabs to the right)
;vOpt: LR (close other tabs)
;vOpt: (blank) (close other tabs)
;vNum: specify a tab other than the focused tab
JEE_FirefoxCloseOtherTabs(hWnd:="", vOpt:="", vNum:="")
{
	local
	if (hWnd = "")
		hWnd := WinExist("A")
	;vWinClass := WinGetClass("ahk_id " hWnd)
	WinGetClass, vWinClass, % "ahk_id " hWnd
	if !(vWinClass = "MozillaWindowClass")
		return
	if (vNum = "")
		vNum := JEE_FirefoxGetFocusedTabNum(hWnd)
	if (vOpt = "")
		vOpt := "LR"
	vDoCloseLeft := !!InStr(vOpt, "L")
	vDoCloseRight := !!InStr(vOpt, "R")

	oAcc := Acc_Get("Object", "4", 0, "ahk_id " hWnd)
	vRet := 0
	for _, oChild in Acc_Children(oAcc)
	{
		if (oChild.accName(0) == "Browser tabs")
		{
			oAcc := Acc_Children(oChild).1, vRet := 1
			break
		}
	}
	if !vRet
	{
		oAcc := oChild := ""
		return
	}

	vRet := 0
	oChildren := Acc_Children(oAcc)
	vIndex := oChildren.Length() + 1
	Loop % vIndex - 1
	{
		vIndex--
		oChild := oChildren[vIndex]
		;ROLE_SYSTEM_PUSHBUTTON := 0x2B
		try
		{
			if (oChild.accRole(0) = 0x2B)
				continue
		}
		if (vIndex = vNum)
			continue
		if (vIndex > vNum) && !vDoCloseRight
			continue
		if (vIndex < vNum) && !vDoCloseLeft
			continue
		;note: cf. Chrome, Firefox doesn't have a separate Close button element
		;oChild2 := Acc_Children(oChild).4
		;if (oChild2.accName(0) = "Close")
		;	oChild2.accDoDefaultAction(0)
		;oChild2 := ""
		;instead we focus each tab and send Ctrl+W to it
		JEE_FirefoxFocusTabByNum(hWnd, vIndex)
		;Sleep(500)
		DllCall("kernel32\Sleep", "UInt",500)
		;ControlSend("{Ctrl down}w{Ctrl up}",, "ahk_id " hWnd)
		ControlSend, ahk_parent, {Ctrl down}w{Ctrl up}, % "ahk_id " hWnd
	}
	oAcc := oChild := ""
	return vRet
}

;==================================================

TCMatch(aHaystack, aNeedle)
{
  chars := "/\[^$.|?*+(){}"
  for i, e in StrSplit(chars)
    aHaystack := StrReplace(aHaystack, e, A_Space)
  if (A_PtrSize == 8)
  {
    return DllCall("lib\TCMatch64\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
  }
  return DllCall("lib\TCMatch\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
}
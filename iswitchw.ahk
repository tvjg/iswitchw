;----------------------------------------------------------------------
;
; User configuration
;
#SingleInstance force
#NoTrayIcon
#Include Chrome.ahk

; Use small icons in the listview
Global compact := true

; A bit of a hack, but this 'hides' the scorlls bars, rather the listview is
; sized out of bounds, you'll still be able to use the scroll wheel or arrows
; but when resizing the window you can't use the left edge of the window, just
; the top and bottom right.
Global hideScrollBars := true

; Activate the window if it's the only match
activateOnlyMatch := false

; Hides the UI when focus is lost!
hideWhenFocusLost := true

; Window titles containing any of the listed substrings are filtered out fromin
; useful for things like  hiding improperly configured tool windows or screen
; capture software during demos.
filters := []

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
;     chromeInst  - object for connected Chrome debug protocol session
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

AutoTrim, off

Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow +Resize +Hwndswitcher_id
Gui, Color, black, 191919
; 2e2d2d, 262525
WinSet, Transparent, 225
Gui, Margin, 8, 10
Gui, Font, s14 cEEE8D5, Segoe MDL2 Assets
Gui, Add, Text,     xm+5 ym+3, % Chr(0xE721)
Gui, Font, s10 cEEE8D5, Segoe UI
Gui, Add, Edit,     w420 h25 x+10 ym gSearchChange vsearch -E0x200,
Gui, Add, ListView, % (hideScrollbars ? "x0" : "x9") " y+4 w490 h500  -VScroll -HScroll -Hdr -Multi Count10 AltSubmit vlist gListViewClick +LV0x10000 -E0x200", index|title|proc
Gui, Show, % x ? "x" x " y" y " w" w " h" h : "" , Window Switcher
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

;----------------------------------------------------------------------
;
; Win+space to activate.
;
#space::
; CapsLock:: ; Use Shift+Capslock to toggle while in use by the hotkey
If WinActive("ahk_class Windows.UI.Core.CoreWindow") ; clear the search/start menu if it's open, otherwise it keeps stealing focus
  Send, {esc}
search =
lastSearch =
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

#If WinActive("ahk_id" switcher_id)
Enter::       ;Activate window
Escape::      ;Close window
^Backspace::  ;Clear text
Down::        ;Next row
Tab::         
^h::
^k::
^j::
^w::
Up::          ;Previous row
+Tab::        
PgUp::        ;Jump up 4 rows
PgDn::        ;Jump down 4 rows
Home::        ;Jump to top
End::         ;Jump to bottom
!F4::         ;Quit
~Delete::
~Backspace::
  SetKeyDelay, -1
  Switch A_ThisHotkey {
    Case "Enter":       ActivateWindow()
    Case "Escape":      WinHide, ahk_id %switcher_id%
    Case "Home":        LV_Modify(1, "Select Focus Vis")
    Case "End":         LV_Modify(LV_GetCount(), "Select Focus Vis")
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
  ? (compact ? 160 : 180)   ; Resizes column 3 to match gui width
  : (compact ? 190 : 210)))
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
  if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  Gui, Submit, NoHide
  RefreshWindowList()
  If (LV_GetCount() > 1) {
    Gui, Font, % LV_GetCount() > 1 && windows.MaxIndex() < 1 ? "cff2626" : "cEEE8D5"
    GuiControl, Font, Edit1
  } Else if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  OutputDebug, % "lvcount: " LV_GetCount() " - windows: " windows.MaxIndex() "`n"
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

  WinGet, id, list, , , Program Manager
  Loop, %id%
  {
    StringTrimRight, wid, id%a_index%, 0
    WinGetTitle, title, ahk_id %wid%
    StringTrimRight, title, title, 0

    ; FIXME: windows with empty titles?
    if title =
      continue

    ; don't add the switcher window
    if switcher_id = %wid%
      continue

    ; don't add titles which match any of the filters
    if IncludedIn(filters, title) > -1
      continue

    ; replace pipe (|) characters in the window title,
    ; because Gui Add uses it for separating listbox items
    StringReplace, title, title, |, -, all

    procName := GetProcessName(wid)
    windows.Insert({ "id": wid, "title": title, "procName": procName })
  }
  If WinExist("ahk_exe chrome.exe") {
    Try {
      If (Chromes := Chrome.FindInstances()) {
        ChromeInst := {"base": Chrome, "DebugPort": Chromes.MinIndex()}
        list := ChromeInst.GetPageList()
        for i, e in list {
          if (InStr(e.type,"page") && !InStr(e.url,"chrome-extension"))
            windows.Insert({ "url": e.url, "title": e.title, "procName":"Chrome tab" })
        }
      }
    }
  }
  return windows
}

;----------------------------------------------------------------------
;
; Refresh the list of windows according to the search criteria
;
RefreshWindowList()
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
BuildFilterExpression(term)
{
  expr := "i)"
  Loop, parse, term
  {
    expr .= "[^" . A_LoopField . "]*" . A_LoopField
  }

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
  Gui Submit
  wid := windows[rowNum].id
  procName := windows[rowNum].procName
  ; In some cases, calling WinMinimize minimizes the window, but it retains its
  ; focus preventing WinActivate from raising window.
  If (procName = "Chrome tab") {
    Try {
      url := windows[rowNum].url
      page := ChromeInst.GetPageByURL(url,"exact")
      page.Call("Page.bringToFront")
      WinActivate, ahk_exe chrome.exe
      page.Disconnect()
    }
  } Else {
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
  Global Chromes, switcher_id
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

    iconNumber =

    if (procName = "Chrome tab" or isAppWindow or ( !ownerHwnd and !isToolWindow ))
    {
      if (procName = "Chrome tab") ; Apply the Chrome icon to found Chrome tabs
        wid := WinExist("ahk_exe chrome.exe")
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

      if (iconHandle <> 0)
        iconNumber := DllCall("ImageList_ReplaceIcon", UInt, imageListID, Int, -1, UInt, iconHandle) + 1

    } else {
      WinGetClass, Win_Class, ahk_id %wid%
      if Win_Class = #32770 ; fix for displaying control panel related windows (dialog class) that aren't on taskbar
        iconNumber := IL_Add(imageListID, "C:\WINDOWS\system32\shell32.dll", 217) ; generic control panel icon
    }

    if (iconNumber < 1 || (procName == "chrome" && IsObject(Chromes))) { ; Don't list the Chrome window if connected to debug session
      removedRows.Insert(idx)
    } else {
      iconCount+=1
      LV_Add("Icon" . iconNumber, iconCount, window.procName, title)
    }
  }

  ; Don't draw rows without icons.
  windowCount-=removedRows.MaxIndex()
  For key,rowNum in removedRows
  {
    windows.Remove(rowNum)
  }

  LV_Modify(1, "Select Focus")

  LV_ModifyCol(1,compact ? 40 : 60)
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
    gH -= 10, gW -= 10
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

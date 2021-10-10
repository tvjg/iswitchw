;----------------------------------------------------------------------
; ENSURE YOU'RE RUNNING WITH THE x64 VERSION OF AHK
; FOR PROPER BROWSER TAB SUPPORT
;
; Vivaldi support is presently broken
;
;

;----------------------------------------------------------------------
;
; User configuration
;

; Use small icons in the listview
Global compact := true

; A bit of a hack, but this 'hides' the scorlls bars, rather the listview is
; sized out of bounds, you'll still be able to use the scroll wheel or arrows
; but when resizing the window you can't use the left edge of the window, just
; the top and bottom right.
Global hideScrollBars := true

; Uses tcmatch.dll included with QuickSearch eXtended by Samuel Plentz
; https://www.ghisler.ch/board/viewtopic.php?t=22592
; Supports Regex, Simularity, Srch & PinYin
; Included in lib folder, no license info that I could find
; see readme in lib folder for details, use the included tcmatch.ahk to change settings
; By default, for different search modes, start the string with:
;   ? - for regex
;   * - for srch    
;   < - for simularity
; recommended '*' for fast fuzzy searching; you can set one of the other search modes as default here instead if destired
DefaultTCSearch := "*" 

; Activate the window if it's the only match
activateOnlyMatch := false

; Hides the UI when focus is lost!
hideWhenFocusLost := true

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

#SingleInstance force
#NoTrayIcon
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

#Include lib\Accv2.ahk

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
Loop 300 {
    KeyFunc := Func("ActivateWindow").Bind(A_Index)
    Hotkey, IfWinActive, % "ahk_id" switcher_id
    Hotstring(":X:" A_Index , KeyFunc)
}

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
      If (SubStr(search, 1, 1) != "?"
      && DefaultTCSearch != "?"
      && ((windows.MaxIndex() < 1 && LV_GetCount() > 1) || LV_GetCount() = 1))
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
  Gui, Submit, NoHide
  if ((search ~= "^\d+")
  || (StrLen(search) = 1 && SubStr(search, 1, 1) ~= "[?*<]"))
    return  
  Settimer, Refresh, -1
Return

Refresh:
  if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  StartTime := A_TickCount
  RefreshWindowList()
  ElapsedTime := A_TickCount - StartTime
  If (LV_GetCount() > 1) {
    Gui, Font, % LV_GetCount() > 1 && windows.MaxIndex() < 1 ? "cff2626" : "cEEE8D5"
    GuiControl, Font, Edit1
  } Else if (LV_GetCount() = 1) {
    Gui, Font, c90ee90fj
    GuiControl, Font, Edit1
  }
  For i, e in windows {
    str .= Format("{:-4} {:-15} {:-55}`n",A_Index ":",SubStr(e.procName,1,14),StrLen(e.title) > 50 ? SubStr(e.title,1,50) "..." : e.title)
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
GetAllWindows() {
  global switcher_id, filters
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
          if RegExMatch(e, "i)(.*) - Part of.*group\s?(.*)", match) ; appends group name to grouped tabs
            e := (match2 ? match2 : "Group") . " " . Chr(0x2022) . " " . match1
          windows.Push({"id":next, "title": e, "procName": "Chrome tab", "num": i})
        }
      } else if (procName = "firefox") {
        tabs := StrSplit(JEE_FirefoxGetTabNames(next),"`n")
        for i, e in tabs
          windows.Push({"id":next, "title": e, "procName": "Firefox tab", "num": i})
    ;   } else if (procName = "vivaldi") {
    ;     tabs := StrSplit(VivaldiGetTabNames(next),"`n")
    ;     for i, e in tabs {
    ;       tab := StrSplit(e, "¥")
    ;       if !tab.1
    ;         continue
    ;       windows.Push({"id":next, "title": tab.1, "procName": "Vivaldi tab", "num": tab.2, "row": tab.3, "num2": tab.4})
    ;     }
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
  windows := []
  toRemove := ""
  If (DefaultTCSearch = "?" || SubStr(search, 1, 1) = "?" ||  !search || refreshEveryKeystroke || StrLen(search) < StrLen(lastSearch)) {
    allwindows := GetAllWindows()
    for _, e in fileList {
      path := e.path 
      SplitPath, path, OutFileName, OutDir, OutExt, OutNameNoExt, OutDrive
      RegExMatch(OutDir, "\\(\w+)$", folder)
      allwindows.Push({"procname":folder1,"title":e.fileName . (!RegExMatch(OutExt,"txt|lnk") ? "." OutExt : "" ),"path":e.path})
    }
  }
  lastSearch := search
  for i, e in allwindows {
    str := e.procName " " e.title
    if !search || TCMatch(str,search) {
      windows.Push(e)
    } else {
      toRemove .= i ","
    }
  }
  OutputDebug, % "Allwindows count: " allwindows.MaxIndex() " | windows count: " windows.MaxIndex() "`n"
  DrawListView(windows)
  for i, e in StrSplit(toRemove,",")
    allwindows.Delete(e)
}

ActivateWindow(rowNum := "") {

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
  If window.HasKey("path") {
    Run, % """" path """" 
  } Else {
    If (procName = "Chrome tab")
      JEE_ChromeFocusTabByNum(wid,num)
    Else If (procName = "Firefox tab")
      JEE_FirefoxFocusTabByNum(wid,num)
    ; Else If (procName = "Vivaldi tab")
    ;   VivaldiFocusTabByNum(wid,num,window.row,window.num2)
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
DrawListView(windows) {
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
  GuiControl, -Redraw, list
  For idx, window in windows {

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
    } else if (procName ~= "(Chrome|Firefox) tab" || isAppWindow || ( !ownerHwnd and !isToolWindow )) {
    ; } else if (procName ~= "(Chrome|Firefox|Vivaldi) tab" || isAppWindow || ( !ownerHwnd and !isToolWindow )) {
      if !(iconHandle := window.icon) {
        if (procName = "Chrome tab") ; Apply the Chrome icon to found Chrome tabs
          wid := WinExist("ahk_exe chrome.exe")
        else if (procName = "Firefox tab")
          wid := WinExist("ahk_exe firefox.exe")
        ; else if (procName = "Vivaldi tab")
        ;   wid := WinExist("ahk_exe vivaldi.exe")
        ; http://www.autohotkey.com/docs/misc/SendMessageList.htm
        WM_GETICON := 0x7F

        ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms632625(v=vs.85).aspx
        ICON_BIG := 1
        ICON_SMALL2 := 2
        ICON_SMALL := 0
        SendMessage, WM_GETICON, ICON_BIG, 0, , ahk_id %wid%
        iconHandle := ErrorLevel
        if (iconHandle = 0) {
          SendMessage, WM_GETICON, ICON_SMALL2, 0, , ahk_id %wid%
          iconHandle := ErrorLevel
          if (iconHandle = 0) {
            SendMessage, WM_GETICON, ICON_SMALL, 0, , ahk_id %wid%
            iconHandle := ErrorLevel
            if (iconHandle = 0) {
              ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms633581(v=vs.85).aspx
              ; To write code that is compatible with both 32-bit and 64-bit
              ; versions of Windows, use GetClassLongPtr. When compiling for 32-bit
              ; Windows, GetClassLongPtr is defined as a call to the GetClassLong
              ; function.
              iconHandle := DllCall("GetClassLongPtr", "uint", wid, "int", -14) ; GCL_HICON is -14

              if (iconHandle = 0) {
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
  GuiControl, +Redraw, list

  ; Don't draw rows without icons.
  windowCount-=removedRows.MaxIndex()
  For key,rowNum in removedRows {
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

VivaldiAccInit() {
    static vTabs := 0
    If !vTabs {
        vTabs := JEE_AccGetTextAll(WinExist("ahk_exe vivaldi.exe"), "Menu", "push button")
        vTabs := RegExReplace(vTabs, ".{3}$", "2.1.1.1")
    }
    return vTabs
}

; Needs improvement, can currently only get tab names for stacked tab groups if they're visible/expanded
VivaldiGetTabNames(hwnd) {
    vTabs := VivaldiAccInit()
    oAcc := Acc_Get("Object", vTabs, 0, "ahk_id" hwnd)
    oChildren := Acc_Children(oAcc)
		for _, oChild in oChildren
		{
			if ( name := oChild.accName(1) )
			{
				vNum++ 
        Try
			  if ( oChild.accRole(2) = 20 ) {   
          oStepchildren := Acc_Children(Acc_Children(oChild)[2])
          for vNum2, oStepchild in oStepchildren {
            name2 := oStepchild.accName(0)
            if (name = name2)
              Continue
            str2 .= RepStr(A_Space,3) . Chr(0x25AA) " " name2 . "¥" . vNum . "¥" . 2 . "¥" vNum2 "`n"
          }
          name := Chr(0x25CF) " " name
        }
    	  str .= name "¥" vNum "¥" 1 "`n" . (str2 ? str2 : ""), str2 := ""
			}
		}
    return str
}

RepStr( Str, Count ) { ; By SKAN / CD: 01-July-2017 | goo.gl/U84K7J
Return StrReplace( Format( "{:0" Count "}", "" ), 0, Str )
}

/* 
[class] imagebutton
4.1.2.1.1.1.1.1.1.2.1.1.1.1.1
4.1.2.1.1.1.1.1.1.2.1.1.1.1.2.1
4.1.2.1.1.1.1.1.1.2.1.1.1.1.2.2
 */

VivaldiFocusTabByNum(hWnd:="", vNum:="", row := "", vNum2 := "") {
	local
	if !vNum
		return
        
    path := VivaldiAccInit()
	if (hWnd = "")
		hWnd := WinExist("A")
    tabRow := Acc_Get("Object", path, 0, "ahk_id" hwnd)
    oChild := Acc_Children(tabRow)[vNum]
  if (row = 1) {
    oChild.accDoDefaultAction(0)
  } else if (row = 2) {
    oChild := Acc_Children(oChild)[row]
    oChild := Acc_Children(oChild)
    oChild[vNum2].accDoDefaultAction(0)
  } else {
    vNum := ""
  }
  clipboard := ";name:" name "`n;" path "." vNum "." row . (vNum2 ? "." vNum2 : "")
	return vNum
}



;https://autohotkey.com/boards/viewtopic.php?f=6&t=40615

JEE_ChromeAccInit(vValue)
{
    static vTabs := 0
    chrome := WinExist("ahk_exe chrome.exe")
    if !vTabs
        vTabs := JEE_AccGetTextAll(chrome,,"page tab list") . ".1"
	if (vValue = "U1")
		return "4.1.2.1.2.5.2" ;address bar
	if (vValue = "U2")
		return "4.1.2.2.2.5.2" ;address bar
	if (vValue = "T")
		return vTabs ? vTabs : 0 ;"4.1.2.1.1.1" ;tabs (append '.1' to get the first tab)
}

JEE_ChromeGetTabNames(hWnd:="", vSep:="`n")
{
	local
	static vAccPath
    if !vAccPath
        vAccPath := JEE_ChromeAccInit("T")
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
	static vAccPath
    if !vAccPath
        vAccPath := JEE_ChromeAccInit("T")    
	; static vAccPath := JEE_ChromeAccInit("T")
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

TCMatch(aHaystack, aNeedle)
{
  global DefaultTCSearch

  if (SubStr(aNeedle, 1, 1) != "?" && DefaultTCSearch != "?" )  {
    for i, e in StrSplit("/\[^$.|?*+(){}")
      aHaystack := StrReplace(aHaystack, e, A_Space)
  }
  If ( aNeedle ~= "^[^\?<*]" && DefaultTCSearch )
    aNeedle := DefaultTCSearch . aNeedle
  OutputDebug, % aNeedle "`n"
  if (A_PtrSize == 8)
  {
    return DllCall("lib\TCMatch64\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
  }
  return DllCall("lib\TCMatch\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
}

;Modified from original to allow searching for and returning a match for role, name and value, whichever are entered.
JEE_AccGetTextAll(hWnd:=0, nameMatch := "", roleMatch := "", valMatch := "", vSep:="`n", vIndent:="`t", vOpt:="")
{
	vLimN := 20, vLimV := 20
	Loop, Parse, vOpt, % " "
	{
		vTemp := A_LoopField
		if (SubStr(vTemp, 1, 1) = "n")
			vLimN := SubStr(vTemp, 2)
		else if (SubStr(vTemp, 1, 1) = "v")
			vLimV := SubStr(vTemp, 2)
	}
    matchList := Object()
    if (nameMatch != "")
        matchList.vName := nameMatch
    if (roleMatch != "")
        matchList.vRoleText := roleMatch
    if (valMatch != "")
        matchList.vValue  := valMatch
    

	oMem := {}, oPos := {}
	;OBJID_WINDOW := 0x0
	oMem[1, 1] := Acc_ObjectFromWindow(hWnd, 0x0)
	oPos[1] := 1, vLevel := 1
	VarSetCapacity(vOutput, 1000000*2)

	Loop
	{
		if !vLevel
			break
		if !oMem[vLevel].HasKey(oPos[vLevel])
		{
			oMem.Delete(vLevel)
			oPos.Delete(vLevel)
			vLevelLast := vLevel, vLevel -= 1
			oPos[vLevel]++
			continue
		}
		oKey := oMem[vLevel, oPos[vLevel]]

		vName := "", vValue := ""
		if IsObject(oKey)
		{
			vRoleText := Acc_GetRoleText(oKey.accRole(0))
			try vName := oKey.accName(0)
			try vValue := oKey.accValue(0)
		}
		else
		{
			oParent := oMem[vLevel-1,oPos[vLevel-1]]
			vChildId := IsObject(oKey) ? 0 : oPos[vLevel]
			vRoleText := Acc_GetRoleText(oParent.accRole(vChildID))
			try vName := oParent.accName(vChildID)
			try vValue := oParent.accValue(vChildID)
		}
		if (StrLen(vName) > vLimN)
			vName := SubStr(vName, 1, vLimN) "..."
		if (StrLen(vValue) > vLimV)
			vValue := SubStr(vValue, 1, vLimV) "..."
		vName := RegExReplace(vName, "[`r`n]", " ")
		vValue := RegExReplace(vValue, "[`r`n]", " ")

		vAccPath := ""
		if IsObject(oKey)
		{
			Loop, % oPos.Length() - 1
				vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
		}
		else
		{
			Loop, % oPos.Length() - 2
				vAccPath .= (A_Index=1?"":".") oPos[A_Index+1]
			vAccPath .= " c" oPos[oPos.Length()]
		}
		vOutput .= vAccPath "`t" JEE_StrRept(vIndent, vLevel-1) vRoleText " [" vName "][" vValue "]" vSep

        found := 0
        If (matchList.Count() >= 1) {
            for k, v in matchList
                if InStr(%k%,v)
                    found++
            if (found = matchList.Count())
                return vAccPath
        }

		oChildren := Acc_Children(oKey)
		if !oChildren.Length()
			oPos[vLevel]++
		else
		{
			vLevelLast := vLevel, vLevel += 1
			oMem[vLevel] := oChildren
			oPos[vLevel] := 1
		}
	}
	return matchList.Count() >= 1 ? 0 : SubStr(vOutput, 1, -StrLen(vSep))
}

JEE_StrRept(vText, vNum)
{
	if (vNum <= 0)
		return
	return StrReplace(Format("{:" vNum "}", ""), " ", vText)
	;return StrReplace(Format("{:0" vNum "}", 0), 0, vText)
}

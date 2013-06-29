#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; 
; iswitchw - Incrementally switch between windows using substrings
;
; [CREATED by keyboardfreak, 10 October 2004] 
;     http://www.autohotkey.com/forum/viewtopic.php?t=1040 
;
; [MODIFIED by ezuk, 3 July 2008, changes noted below. Cosmetics only.] 
;     http://www.autohotkey.com/forum/viewtopic.php?t=33353; 
;
; [MODIFIED by jixiuf@gmail.com, 11 June 2011] 
;     https://github.com/jixiuf/my_autohotkey_scripts/blob/master/ahk_scripts/iswitchw-plus.ahk 
;
; [MODIFIED by dirtyrottenscoundrel, 28 June 2013] 
;     FIXME: Publish to Github 
;
; Using AutoHotkey version: 1.1.11.01 
; 
; When this script is triggered via its hotkey the list of titles of 
; all visible windows appears. The list can be narrowed quickly to a 
; particular window by typing a substring of a window title. 
; 
; When the list is narrowed the desired window can be selected using 
; the cursor keys and Enter. 
; 
; The window selection can be cancelled with Esc. 
; 
; The switcher can also be operated with the mouse, although it is 
; meant to be used from the keyboard. A mouse click activates the 
; currently selected window. Mouse users may want to change the 
; activation key to one of the mouse keys. 
; 
; 
; For the idea of this script the credit goes to the creators of the 
; iswitchb package for the Emacs editor 
; 
; 
;---------------------------------------------------------------------- 
; 
; User configuration 
; 

; Window titles containing any of the listed substrings are filtered out from
; the list of windows. 
filters := ["asticky", "blackbox"] 

; Set this yes to update the list of windows every time the contents of the 
; listbox is updated. This is usually not necessary and it is an overhead which 
; slows down the update of the listbox, so this feature is disabled by default. 
dynamicwindowlist = 

;---------------------------------------------------------------------- 
; 
; Global variables 
; 
;     allwindows     - windows on desktop 
;     switcher_id    - the window ID of the switcher window 
;     filters        - array of filters for filtering out titles 
;                      from the window list 
; 
;---------------------------------------------------------------------- 

search = 

AutoTrim, off 

Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow 
Gui, Color, black,black
WinSet, Transparent, 225
Gui, Font, s16 cEEE8D5 bold, Consolas
Gui, Margin, 4, 4
Gui, Add, Text,     w100 h30 x6 y8, Search`:
Gui, Add, Edit,     w500 h30 x110 y4 gSearchChange vsearch,
Gui, Add, ListView, w854 h510 x4 y40 -VScroll -HScroll AltSubmit -Hdr -Multi Count10 gListViewClick, index|title|proc

;---------------------------------------------------------------------- 
; 
; Win+space to activate. 
; 
#space::

search =
GuiControl, , Edit1
allwindows := Object()

Gui, Show, Center, Window Switcher 
WinGet, switcher_id, ID, A 
WinSet, AlwaysOnTop, On, ahk_id %switcher_id% 

Loop 
{ 
    Input, input, L1, {enter}{esc}{tab}{backspace}{delete}{up}{down}{left}{right}{home}{end}

    if ErrorLevel = EndKey:enter 
    { 
        GoSub, ActivateWindow 
        break 
    } 
    else if ErrorLevel = EndKey:escape 
    { 
        Gui, cancel 
        break 
    } 
    else if ErrorLevel = EndKey:tab 
    {
        ; FIXME: Tab should advance listview cursor to next item. 
        continue
    }
    ; FIXME: Ctrl+backspace doesn't work.
    else if ErrorLevel = EndKey:backspace 
    { 
        ControlFocus, Edit1, ahk_id %switcher_id% 
        ControlSend, Edit1, {backspace}, ahk_id %switcher_id% 
        continue 
    } 
    else if ErrorLevel = EndKey:delete 
    { 
        ControlFocus, Edit1, ahk_id %switcher_id% 
        ControlSend, Edit1, {delete}, ahk_id %switcher_id% 
        continue 
    } 
    else if ErrorLevel = EndKey:up 
    { 
        Send, {up} 
        continue 
    } 
    else if ErrorLevel = EndKey:down 
    { 
        Send, {down} 
        continue 
    } 
    ; FIXME: Shift selection doesn't work. 
    else if ErrorLevel = EndKey:left 
    { 
        ControlFocus, Edit1, ahk_id %switcher_id% 
        ControlSend, Edit1, {left}, ahk_id %switcher_id% 
        continue 
    } 
    else if ErrorLevel = EndKey:right 
    { 
        ControlFocus, Edit1, ahk_id %switcher_id% 
        ControlSend, Edit1, {right}, ahk_id %switcher_id% 
        continue 
    } 
    else if ErrorLevel = EndKey:home 
    { 
        send, {home}
        continue 
    } 
    else if ErrorLevel = EndKey:end 
    { 
        send, {end}
        continue 
    } 

    ; FIXME: probably other error level cases 
    ; should be handled here (interruption?) 

    ControlFocus, Edit1, ahk_id %switcher_id% 
    Control, EditPaste, %input%, Edit1, ahk_id %switcher_id% 
} 

exit

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
; Runs whenever Edit control is updated 
SearchChange:
  Gui, Submit, NoHide
  Gosub, RefreshWindowList
  return

;---------------------------------------------------------------------- 
; 
; Refresh the list of windows according to the search criteria 
; 
RefreshWindowList: 

    if (dynamicwindowlist = "yes" or allwindows.MinIndex() = "") 
    { 
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
            allwindows.Insert({ "id": wid, "title": title, "procName": procName })
        } 
    } 

    ; filter the window list according to the search criteria 
    windows := Object()
    For idx, window in allwindows
    { 
      ; if there is a search string 
      if search <> 
      {
        title := window.title
        procName := window.procName

        ; don't add the windows not matching the search string 
        titleAndProcName = %title% %procName%

        if titleAndProcName not contains %search%
          continue 
      }   

      windows.Insert(window)
    } 

    DrawListView(windows)

return 

;---------------------------------------------------------------------- 
; 
; Activate selected window 
; 
ActivateWindow: 

Gui, submit 
rowNum:= LV_GetNext(0)
wid := windows[rowNum].id
WinActivate, ahk_id %wid% 

; Destroy gui, listview and associated icon imagelist.
IL_Destroy(imageListID1) 
LV_Delete()

return 

;---------------------------------------------------------------------- 
; 
; Handle mouse click events on the listview 
; 
ListViewClick: 
; FIXME: Click does not activate window 
if (A_GuiControlEvent = "Normal"
    and !GetKeyState("Down", "P") and !GetKeyState("Up", "P"))
    send, {enter} 
return 

;---------------------------------------------------------------------- 
; 
; Add window list to listview  
; 
DrawListView(windows)
{
  windowCount := windows.MaxIndex()
  global imageListID := IL_Create(windowCount, 1, 1)

  ; Attach the ImageLists to the ListView so that it can later display the icons:
  LV_SetImageList(imageListID, 1)
  LV_Delete()

  iconCount = 0
  removedRows := Array() 

  For idx, window in windows
  {
    wid := window.id
    title := window.title

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
    
    if (isAppWindow or ( !ownerHwnd and !isToolWindow )) 
    {
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

    if iconNumber > 0
    {
      iconCount+=1
      LV_Add("Icon" . iconNumber, iconCount, title, window.procName)
    } else {
      removedRows.Insert(idx)
    } 
  }

  ; Don't draw rows without icons.  
  windowCount-=removedRows.MaxIndex()
  For key,rowNum in removedRows
  {
    windows.Remove(rowNum)
  }
 
  if windowCount > 1
  {
    ; Select and focus the second row. 
    LV_Modify(2, "Select") 
    LV_Modify(2, "Focus")
  } else {
    ; Select and focus the first row. 
    LV_Modify(1, "Select")
    LV_Modify(1, "Focus")
  }

  LV_ModifyCol(1,60)
  LV_ModifyCol(2,650)
  LV_ModifyCol(3,140)
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

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
; [MODIFIED by jixiuf@gmail.com, 3 July 2008] 
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

; set this to yes to enable digit shortcuts when there are ten or 
; less items in the list 
digitshortcuts = 

; set this to yes to enable first letter match mode where the typed 
; search string must match the first letter of words in the 
; window title (only alphanumeric characters are taken into account) 
; 
; For example, the search string "ad" matches both of these titles: 
; 
;  AutoHotkey - Documentation 
;  Anne's Diary 
; 
firstlettermatch = 

; set this to yes to enable activating the currently selected 
; window in the background 
activateselectioninbg =  

; number of milliseconds to wait for the user become idle, before 
; activating the currently selected window in the background 
; 
; it has no effect if activateselectioninbg is off 
; 
; if set to blank the current selection is activated immediately 
; without delay 
bgactivationdelay = 300 

; Close switcher window if the user activates an other window. 
; It does not work well if activateselectioninbg is enabled, so 
; currently they cannot be enabled together. 
closeifinactivated = 

if activateselectioninbg <> 
    if closeifinactivated <> 
    { 
        msgbox, activateselectioninbg and closeifinactivated cannot be enabled together 
        exitapp 
    } 

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
;     numallwin      - the number of windows on the desktop 
;     allwindows     - associative array: titles of windows on desktop keyed
;                      by window ids  
;     numwin         - the number of windows in the listbox 
;     idarray        - array containing window ids for the listbox items 
;     orig_active_id - the window ID of the originally active window 
;                      (when the switcher is activated) 
;     prev_active_id - the window ID of the last window activated in the 
;                      background (only if activateselectioninbg is enabled) 
;     switcher_id    - the window ID of the switcher window 
;     filters        - array of filters for filtering out titles 
;                      from the window list 
; 
;---------------------------------------------------------------------- 

AutoTrim, off 

Gui, +LastFound +AlwaysOnTop -Caption +ToolWindow 
Gui, Color, black,black
WinSet, Transparent, 225
Gui,Font,s16 cEEE8D5 bold,Consolas
Gui,Margin,1,1
Gui, Add, ListView, w854 h510 -VScroll AltSubmit -Hdr -HScroll -Multi Count10 gListViewClick, index|title|proc

;---------------------------------------------------------------------- 
; 
; Win+space to activate. 
; 
#space::

search = 
numallwin = 0 
GuiControl,, Edit1 
GoSub, RefreshWindowList 

WinGet, orig_active_id, ID, A 
prev_active_id = %orig_active_id% 

Gui, Show, Center, Window Switcher 
; If we determine the ID of the switcher window here then 
; why doesn't it appear in the window list when the script is 
; run the first time? (Note that RefreshWindowList has already 
; been called above). 
; Answer: Because when this code runs first the switcher window 
; does not exist yet when RefreshWindowList is called. 
WinGet, switcher_id, ID, A 
WinSet, AlwaysOnTop, On, ahk_id %switcher_id% 

Loop 
{ 
    if closeifinactivated <> 
        settimer, CloseIfInactive, 200 

    Input, input, L1, {enter}{esc}{backspace}{up}{down}{pgup}{pgdn}{tab}{left}{right} 

    if closeifinactivated <> 
        settimer, CloseIfInactive, off 

    if ErrorLevel = EndKey:enter 
    { 
        GoSub, ActivateWindow 
        break 
    } 

    if ErrorLevel = EndKey:escape 
    { 
        Gui, cancel 

        ; restore the originally active window if 
        ; activateselectioninbg is enabled 
        if activateselectioninbg <> 
            WinActivate, ahk_id %orig_active_id% 

        break 
    } 

    if ErrorLevel = EndKey:backspace 
    { 
        GoSub, DeleteSearchChar 
        continue 
    } 

    if ErrorLevel = EndKey:tab 
        if completion = 
            continue 
        else 
            input = %completion% 

    ; pass these keys to the selector window 

    if ErrorLevel = EndKey:up 
    { 
        Send, {up} 
        GoSuB ActivateWindowInBackgroundIfEnabled 
        continue 
    } 

    if ErrorLevel = EndKey:down 
    { 
        Send, {down} 
        GoSuB ActivateWindowInBackgroundIfEnabled 
        continue 
    } 

    if ErrorLevel = EndKey:pgup 
    { 
        Send, {pgup} 

        GoSuB ActivateWindowInBackgroundIfEnabled 
        continue 
    } 

    if ErrorLevel = EndKey:pgdn 
    { 
        Send, {pgdn} 
        GoSuB ActivateWindowInBackgroundIfEnabled 
        continue 
    } 

    if ErrorLevel = EndKey:left 
    { 
        continue 
    } 

    if ErrorLevel = EndKey:right 
    { 
        continue 
    } 

    ; FIXME: probably other error level cases 
    ; should be handled here (interruption?) 

    ; invoke digit shortcuts if applicable 
    if digitshortcuts <> 
        if numwin <= 10 
            if input in 1,2,3,4,5,6,7,8,9,0 
            { 
                if input = 0 
                    input = 10 

                if numwin < %input% 
                { 
                    continue 
                } 

                GuiControl, choose, ListBox1, %input% 
                GoSub, ActivateWindow 
                break 
            } 

    ; process typed character 

    search = %search%%input% 
    GuiControl,, Edit1, %search% 
    GoSub, RefreshWindowList 
} 

Gosub, CleanExit 

return 

  ; Unoptimized array search, returns index of first occurrence or -1 
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
; Refresh the list of windows according to the search criteria 
; 
; Sets: numwin  - see the documentation of global variables 
;       idarray - see the documentation of global variables 
; 
RefreshWindowList: 
    allwindows := Object()
    windows := Object()

    if ( dynamicwindowlist = "yes" or numallwin = 0 ) 
    { 
        numallwin = 0 

        WinGet, id, list, , , Program Manager 
        Loop, %id% 
        { 
            StringTrimRight, this_id, id%a_index%, 0 
            WinGetTitle, title, ahk_id %this_id% 
            StringTrimRight, title, title, 0 

            ; FIXME: windows with empty titles? 
            if title = 
              continue 

            ; don't add the switcher window 
            if switcher_id = %this_id% 
              continue 

            ; don't add titles which match any of the filters 
            if IncludedIn(filters, title) > -1
              continue

            ; replace pipe (|) characters in the window title, 
            ; because Gui Add uses it for separating listbox items 
            StringReplace, title, title, |, -, all 

            numallwin += 1 
            allwindows[this_id] := title
        } 
    } 

    ; filter the window list according to the search criteria 

    winlist = 
    numwin = 0 

    For wid, title in allwindows
    { 
        ; don't add the windows not matching the search string 
        ; if there is a search string 
        if search <> 
            if firstlettermatch = 
            { 
                if title not contains %search%, 
                    continue 
            } 
            else 
            { 
                stringlen, search_len, search 

                index = 1 
                match = 

                loop, parse, title, %A_Space% 
                {                    
                    stringleft, first_letter, A_LoopField, 1 

                    ; only words beginning with an alphanumeric 
                    ; character are taken into account 
                    if first_letter not in 1,2,3,4,5,6,7,8,9,0,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z 
                        continue 

                    stringmid, search_char, search, %index%, 1 

                    if first_letter <> %search_char% 
                        break 

                    index += 1 

                    ; no more search characters 
                    if index > %search_len% 
                    { 
                        match = yes 
                        break 
                    } 
                } 

                if match = 
                    continue    ; no match 
            } 

        if winlist <> 
            winlist = %winlist%| 
        winlist = %winlist%%title%`r%wid% 

        numwin += 1 
        windows[wid] := title
    } 

    ; add digit shortcuts if there are ten or less windows 
    ; in the list and digit shortcuts are enabled 
    if digitshortcuts <> 
        if numwin <= 10 
        { 
            digitlist = 
            digit = 1 
            loop, parse, winlist, | 
            { 
                ; FIXME: windows with empty title? 
                if A_LoopField <> 
                { 
                    if digitlist <> 
                        digitlist = %digitlist%| 
                    digitlist = %digitlist%%digit%%A_Space%%A_Space%%A_Space%%A_LoopField% 

                    digit += 1 
                    if digit = 10 
                        digit = 0 
                } 
            } 
            winlist = %digitlist% 
        } 

    DrawListView(windows)    

    GoSub ActivateWindowInBackgroundIfEnabled 

return 

;---------------------------------------------------------------------- 
; 
; Delete last search char and update the window list 
; 
DeleteSearchChar: 

if search = 
    return 

StringTrimRight, search, search, 1 
GuiControl,, Edit1, %search% 
GoSub, RefreshWindowList 

return 

;---------------------------------------------------------------------- 
; 
; Activate selected window 
; 
ActivateWindow: 

Gui, submit 
stringtrimleft, window_id, idarray%index%, 0 
WinActivate, ahk_id %window_id% 

return 

;---------------------------------------------------------------------- 
; 
; Activate selected window in the background 
; 
ActivateWindowInBackground: 

guicontrolget, index,, ListBox1 
stringtrimleft, window_id, idarray%index%, 0 

if prev_active_id <> %window_id% 
{ 
    WinActivate, ahk_id %window_id% 
    WinActivate, ahk_id %switcher_id% 
    prev_active_id = %window_id% 
} 

return 

;---------------------------------------------------------------------- 
; 
; Activate selected window in the background if the option is enabled. 
; If an activation delay is set then a timer is started instead of 
; activating the window immediately. 
; 
ActivateWindowInBackgroundIfEnabled: 

if activateselectioninbg = 
    return 

; Don't do it just after the switcher is activated. It is confusing 
; if active window is changed immediately. 
WinGet, id, ID, ahk_id %switcher_id% 
if id = 
    return 

if bgactivationdelay = 
    GoSub ActivateWindowInBackground 
else 
    settimer, BgActivationTimer, %bgactivationdelay% 

return 

;---------------------------------------------------------------------- 
; 
; Check if the user is idle and if so activate the currently selected 
; window in the background 
; 
BgActivationTimer: 

settimer, BgActivationTimer, off 

GoSub ActivateWindowInBackground 

return 

;---------------------------------------------------------------------- 
; 
; Stop background window activation timer if necessary and exit 
; 
CleanExit: 

settimer, BgActivationTimer, off 

exit 

;---------------------------------------------------------------------- 
; 
; Cancel keyboard input if GUI is closed. 
; 
GuiClose: 

send, {esc} 

return 

;---------------------------------------------------------------------- 
; 
; Handle mouse click events on the listview 
; 
ListViewClick: 
if (A_GuiControlEvent = "Normal"
    and !GetKeyState("Down", "P") and !GetKeyState("Up", "P"))
    send, {enter} 
return 

;---------------------------------------------------------------------- 
; 
; Close the switcher window if the user activated an other window 
; 
CloseIfInactive: 

ifwinnotactive, ahk_id %switcher_id% 
    send, {esc} 

return

DrawListView(windows)
{
  global numwin
  global imageListID := IL_Create(numwin, 1, 1)

  ; Attach the ImageLists to the ListView so that it can later display the icons:
  LV_SetImageList(imageListID, 1)
  LV_Delete()

  iconCount = 0

  For wid, title in windows
  {
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
      LV_Add("Icon" . iconNumber, iconCount, title, GetProcessName(wid))
    }
  }

  LV_ModifyCol(1,60)
  LV_ModifyCol(2,650)
  LV_ModifyCol(3,140)
}

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

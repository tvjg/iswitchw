# iswitchw 
## fast keyboard-driven window switching via AutoHotKey

When iswitchw is triggered, the titles of all visible windows are shown in a
popup. Start typing to narrow possible matches -- hit enter at any point to
activate the top match. Matches are narrowed using an approximate/'fuzzy'
filtering method similar to tools like [Ido][ido] and [CtrlP][ctrlp].

Built and tested using AutoHotkeyL v1.1.33.02 on Windows 10 (x64).

![screenshot](https://user-images.githubusercontent.com/24360832/116187876-3f996c00-a6db-11eb-888a-b2f2303d201d.png)

### Usage

iswitchw strives to be as intuitive as possible.

* `Capslock` activates iswitchw
* `Esc` cancels at any time
* `Tab/Shift + Tab` `Down/Up` `Ctrl + J/K` navigate next/previous row
* `Left/Right` arrow keys move the insert cursor in the search box
* `Home/End` jump to the top/bottom of list
* `PgDn/PgUp` jumps down/up the list 4 rows at a time
* `Ctrl + Delete/Backspace/W` removes a word from the search, or,
  if there's no further matches or only a single match: clear the input
* `Ctrl + Left/Right` arrow keys skip forward/backward by the word
* `Win + 0-9` focuses the corresponding tab
* `1-99` hotstrings to focus any tab, enter the row number followed by
  a space.
* Click a title to activate a window with the mouse
* Any other typing should be passed through to the search

Chrome and Firefox tabs will appear separately in the list.

By default, iswitchw is restricted to a single instance and hides itself from
the tray. Run the script again at any time to replace the running instance. If
you want to quit the script entirely, activate iswitchw with `Capslock` and
then press `Alt + F4`.

If you want iswitchw to run when Windows starts, make a shortcut to the
iswitchw.ahk file in the folder `%APPDATA%\Microsoft\Windows\Start
Menu\Programs\Startup`. See [here][start-on-boot] also.

### Options

User configurable options are presented at the top of the ahk script.

### Todo

* [ ] Add better explanations/examples for configuration options
* [ ] Move hotkey binding and options into ini file

### History

Original inspiration provided by the creators of the [iswitchb][iswitchb]
package for the Emacs editor.

2004/10/10, CREATED by keyboardfreak         [[link][hist1]]  
2008/07/03, MODIFIED by ezuk                 [[link][hist2]]  
2011/06/11, MODIFIED by jixiuf               [[link][hist3]]  
2013/08/23, MODIFIED by dirtyrottenscoundrel [[link][hist4]]  
2014/05/30, MODIFIED by tvjg                 [[link][hist5]]

My thanks to the previous contributors to this script. Without your work to
lean on and learn from, I would have never started. My primary goals were to
remove accumulated cruft and publish a version that could be easily forked.
Previous implementations depended heavily on subroutines storing shared program
state in undesignated globals.

Gui and global variables (including user configurable options) were trimmed to
a more reasonable minimum. Window icon display code was fixed for 64-bit
versions of Windows. Approximate search matching a la ido/CtrlP was added. Code
length was reduced significantly. When possible, I attempted to avoid old style
AHK idioms (e.g.  EnvAdd, a%index%) in favor of code that would be more
readable to the majority of programmers.

[ido]: http://www.emacswiki.org/emacs/InteractivelyDoThings
[ctrlp]: http://kien.github.io/ctrlp.vim/
[start-on-boot]: http://windows.microsoft.com/en-us/windows-vista/run-a-program-automatically-when-windows-starts
[iswitchb]: http://www.gnu.org/software/emacs/manual/html_node/emacs/Iswitchb.html
[hist1]: http://www.autohotkey.com/forum/viewtopic.php?t=1040
[hist2]: http://www.autohotkey.com/forum/viewtopic.php?t=33353
[hist3]: https://github.com/jixiuf/my_autohotkey_scripts/blob/master/ahk_scripts/iswitchw-plus.ahk
[hist4]: https://github.com/dirtyrottenscoundrel/iswitchw
[hist5]: https://github.com/tvjg/iswitchw
[chrome.ahk]: https://github.com/G33kDude/Chrome.ahk
[debug]: https://stackoverflow.com/questions/51563287/how-to-make-chrome-always-launch-with-remote-debugging-port-flag

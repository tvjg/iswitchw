# iswitchw 
## fast keyboard-driven window switching via AutoHotKey

When iswitchw is triggered, the titles of all visible windows are shown in a
popup. Start typing to narrow possible matches -- hit enter at any point to
activate the top match. Matches are narrowed using an approximate/'fuzzy'
filtering method similar to tools like [Ido][ido] and [CtrlP][ctrlp].

Built and tested using AutoHotkeyL v1.1.11.01 on Windows 7 (x64).

### Usage

iswitchw strives to be as intuitive as possible.

* `Win + Space` activates iswitchw  
* `Esc` cancels at any time  
* `Tab` to advance the selected window match  
* `Up/Down` arrow keys move through the matches  
* `Left/Right` arrow keys move the insert cursor in the search box  
* `Home/End` move the insert cursor or match selection depending on context  
* `Ctrl + Delete/Backspace` removes a word from the search  
* `Ctrl + Left/Right` arrow keys skip forward/backward by the word  
* Click a title to activate a window with the mouse  
* Any other typing should be passed through to the search  

### Options

User configurable options are presented at the top of the ahk script.

### Example

![iswitchw in action](./using-iswitchw.gif?raw=true)

### Todo

* [ ] Tweak scoring algorithm to work better with long window titles
* [ ] Add better explanations/examples for configuration options

### History

Original inspiration provided by the creators of the [iswitchb][iswitchb]
package for the Emacs editor.

2004/10/10, CREATED by keyboardfreak         [[link][hist1]]  
2008/07/03, MODIFIED by ezuk                 [[link][hist2]]  
2011/06/11, MODIFIED by jixiuf               [[link][hist3]]  
2013/08/23, MODIFIED by dirtyrottenscoundrel [[link][hist4]]  

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
[iswitchb]: http://www.gnu.org/software/emacs/manual/html_node/emacs/Iswitchb.html
[hist1]: http://www.autohotkey.com/forum/viewtopic.php?t=1040
[hist2]: http://www.autohotkey.com/forum/viewtopic.php?t=33353
[hist3]: https://github.com/jixiuf/my_autohotkey_scripts/blob/master/ahk_scripts/iswitchw-plus.ahk
[hist4]: https://github.com/dirtyrottenscoundrel/iswitchw

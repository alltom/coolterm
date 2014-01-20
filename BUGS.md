BUGS
====

* Keyboard shortcuts like Ctrl+D and Ctrl+C don't work.
* You can't scroll the last line to the top of the window.
* Arrow keys move the cursor instead of scrolling the view. (Maybe not a bug??)
* Sometimes text that is off-screen will not be rendered when it scrolls into view. It seems that this happens most often with the prompt that appears after a command finishes executing.
* Formatting changes don't take effect until the selection changes. But after the first time, formatting changes take effect immediately.
* Control codes aren't interpreted. (http://www.pixelbeat.org/scripts/ansi2html.sh)
* Undo stack should be cleared whenever new stuff prints.
* Cannot configure default font.
* No way to enable auto-scroll.
* No way to export history as, say, RTFD or HTML.

BUGS
====

* No auto-complete.
* If you close all windows, no window is opened on next launch.
* Sometimes text that is off-screen will not be rendered when it scrolls into view. It seems that this happens most often with the prompt that appears after a command finishes executing.
* Line height calculation (for scroll-past-end behavior) does not account for font.
* Undo stack should be cleared whenever new stuff prints.
* No way to export history as, say, RTFD or HTML.
* Dock icon doesn't show the number of windows with new content. (Seems like a fun feature, right?)
* Control codes aren't interpreted. (http://www.pixelbeat.org/scripts/ansi2html.sh)
* Formatting changes don't take effect until the selection changes. But after the first time, formatting changes take effect immediately.
* Icon isn't in the OS X style.

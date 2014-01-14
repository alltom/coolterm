BUGS
====

* Keyboard shortcuts like Ctrl+D and Ctrl+C don't work.
* You can't scroll the last line to the top of the window.
* Arrow keys move the cursor instead of scrolling the view.
* Interactive programs don't treat the terminal as interactive. For example, try 'irb', Ruby's shell.
* Sometimes text that is off-screen will not be rendered when it scrolls into view. It seems that this happens most often with the prompt that appears after a command finishes executing.
* Formatting changes don't take effect until the selection changes. But after the first time, formatting changes take effect immediately.
* Control codes aren't interpreted.

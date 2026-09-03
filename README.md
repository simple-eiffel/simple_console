# SIMPLE_CONSOLE

SCOOP-compatible console manipulation with colored text, cursor control, and screen operations.

## Features

- 16 foreground and background colors
- Cursor positioning and visibility control
- Screen and line clearing
- Console title setting
- Screen size detection
- Hidden (no-echo) line input for password prompts
- Thread-safe (SCOOP-compatible)

## Installation

Add to your ECF file:

```xml
<library name="simple_console" location="$SIMPLE_EIFFEL/simple_console/simple_console.ecf"/>
```

Set the environment variable (one-time setup for all simple_* libraries):
```
SIMPLE_EIFFEL=D:\prod
```

## Quick Start

```eiffel
local
    con: SIMPLE_CONSOLE
do
    create con

    -- Set colors
    con.set_foreground (con.Green)
    print ("Success!%N")
    con.reset_color

    -- Print colored text
    con.print_colored ("Error!", con.Red)

    -- Position cursor
    con.set_cursor (10, 5)
    print ("At position (10, 5)")

    -- Clear screen
    con.clear

    -- Set window title
    con.set_title ("My Application")
end
```

## API Overview

### SIMPLE_CONSOLE

| Feature | Description |
|---------|-------------|
| `set_foreground (color)` | Set text color |
| `set_background (color)` | Set background color |
| `set_color (fg, bg)` | Set both colors |
| `reset_color` | Reset to default colors |
| `set_cursor (x, y)` | Move cursor to position |
| `cursor_x, cursor_y` | Get cursor position |
| `show_cursor, hide_cursor` | Toggle cursor visibility |
| `clear` | Clear entire screen |
| `clear_line` | Clear to end of line |
| `set_title (text)` | Set console window title |
| `width, height` | Get console dimensions |
| `print_colored (text, color)` | Print text in color |
| `print_at (text, x, y)` | Print at position |
| `is_stdin_console` | Is standard input a console, not a file or a pipe? |
| `read_hidden_line` | Read one line without echoing it |

## Reading a password

`read_hidden_line` reads ONE line of standard input and answers a
`detachable STRING_32`. It takes one of two paths, and it chooses between
them itself:

- **Standard input is a console.** `ENABLE_ECHO_INPUT` is cleared for the
  duration of the read, so nothing appears on screen as the user types.
  `ENABLE_LINE_INPUT` is kept, so Backspace still edits the line and Enter
  still ends it; `ENABLE_PROCESSED_INPUT` is kept, so Ctrl+C still reaches
  the process. The line is read with `ReadConsoleW`, in UTF-16, so a Hebrew
  or Greek password survives intact. The previous console mode is restored
  on **every** exit path, success or failure - the restore lives in the C
  function itself, not in a happy path or an Eiffel rescue clause, because a
  console left without echo is a console the user cannot type into visibly
  for the rest of the session. Because the user's Enter was not echoed
  either, the feature prints the newline for you.
- **Standard input is redirected** from a file or a pipe - which is how an
  installer's verification script feeds a password in. The line is read the
  ordinary way and decoded as UTF-8. No console mode is touched, and nothing
  is hidden: there is no terminal to hide it from.

On both paths the trailing CR and/or LF is stripped, so a CRLF file written
by a Windows script does not leave a stray CR on the end of the password.

The result is `Void` on end of input or on failure - **never** a partial
line. A line the user ended by pressing Enter alone is the empty string, not
`Void`, so the two cases stay distinguishable.

```eiffel
local
    con: SIMPLE_CONSOLE
do
    create con
    print ("Password: ")
    if attached con.read_hidden_line as l_password then
        -- l_password is a STRING_32, no CR, no LF, never echoed
        create_admin (l_password)
    else
        con.print_error ("No password given.")
    end
end
```

### Trying the console path by hand

The redirected path is covered by the test suite. The console path cannot
be: it needs a real console, and a test runner's standard input is a file or
a pipe. A manual check ships with the test executable. Build it, then run it
from **cmd.exe or Windows Terminal** - not through a pipe, and not from a
mintty shell such as git-bash:

```
ec.sh test -config simple_console.ecf -target simple_console_tests
EIFGENs\simple_console_tests\F_code\simple_console.exe --hidden-line-demo
```

What to look for:

1. `is_stdin_console` reports `True`.
2. Nothing appears on screen while you type the first line.
3. Backspace still erases, and Enter still ends the line.
4. The code points reported back are the ones you typed.
5. The second line, read the ordinary way, **does** echo - that is the proof
   the console mode was put back.

### Color Constants

Black, Dark_blue, Dark_green, Dark_cyan, Dark_red, Dark_magenta, Dark_yellow, Gray, Dark_gray, Blue, Green, Cyan, Red, Magenta, Yellow, White (0-15)

## Documentation

- [API Documentation](https://simple-eiffel.github.io/simple_console/)

## Platform Support

- Windows only (uses Win32 API). The C layer carries a POSIX branch for
  parity, `read_hidden_line` included, but it is not exercised.

## License

MIT License - see LICENSE file for details.

## Author

Larry Rix

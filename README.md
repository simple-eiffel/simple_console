# SIMPLE_CONSOLE

SCOOP-compatible console manipulation with colored text, cursor control, and screen operations.

## Features

- 16 foreground and background colors
- Cursor positioning and visibility control
- Screen and line clearing
- Console title setting
- Screen size detection
- Hidden (no-echo) line input for password prompts
- Masked (dots-per-keystroke) line input for password prompts, so the typist can see their keystrokes registering
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
| `read_hidden_line` | Read one line without echoing it at all |
| `read_masked_line (a_mask)` | Read one line, echoing `a_mask` once per character typed |
| `read_masked_line_default` | `read_masked_line` with `a_mask` set to `'*'` |

## Reading a password

Two features read a password. Both take the same one of two paths, and both
choose between them the same way; the difference between them is only what
happens on the console path.

**`read_hidden_line`** shows the typist NOTHING - not even how many
characters they have typed. **`read_masked_line`** echoes one copy of a
caller-chosen mask character (`read_masked_line_default` uses `'*'`) for
every character accepted, so the typist can tell their keystrokes are
registering without the console ever showing what was typed. This was added
after using 1.1.0's `read_hidden_line` in an installer console:

> I was surprised by not even have dots for pw chars. That meant that I
> didn't know whether my keystrokes were being registered. So, the dots
> would really help.

Use `read_hidden_line` where even the keystroke COUNT should stay
unseen - a shared or recorded screen. Use `read_masked_line` for an ordinary
password prompt.

- **Standard input is a console.**
  - `read_hidden_line` clears `ENABLE_ECHO_INPUT` for the duration of the
    read, so nothing appears on screen as the user types. `ENABLE_LINE_INPUT`
    is kept, so Windows' own line editor still handles Backspace and Enter;
    `ENABLE_PROCESSED_INPUT` is kept, so Ctrl+C still reaches the process.
    The line is read with `ReadConsoleW`, in UTF-16, so a Hebrew or Greek
    password survives intact. Because the user's Enter was not echoed
    either, the feature prints the newline for you.
  - `read_masked_line` clears `ENABLE_LINE_INPUT` too, and becomes the line
    editor itself: it reads one key event at a time and prints one copy of
    `a_mask` for every character accepted. Backspace removes the last
    character typed and erases its one on-screen mask (backspace, space,
    backspace); Enter ends the line and prints its own newline;
    `ENABLE_PROCESSED_INPUT` is left exactly as found, so Ctrl+C keeps
    working; a surrogate pair - most emoji, for instance - is accepted,
    masked, and erased as the ONE character it represents, never as two;
    every other non-character key (arrows, function keys, and the like) is
    silently ignored.
  - Either way, the previous console mode is restored on **every** exit
    path, success or failure - the restore lives in the C function itself,
    not in a happy path or an Eiffel rescue clause, because a console left
    in a raw mode is a console the user cannot type into normally again for
    the rest of the session.
- **Standard input is redirected** from a file or a pipe - which is how an
  installer's verification script feeds a password in. Both features behave
  IDENTICALLY here: the line is read the ordinary way and decoded as UTF-8.
  No console mode is touched, no mask is ever printed, and nothing is
  hidden: there is no terminal to hide it from.

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
    if attached con.read_masked_line_default as l_password then
        -- l_password is a STRING_32, no CR, no LF - each keystroke showed
        -- as a '*' on the console, never the character itself
        create_admin (l_password)
    else
        con.print_error ("No password given.")
    end
end
```

Swap `read_masked_line_default` for `read_hidden_line` wherever the typist
should get no feedback at all - a shared or recorded screen, for instance,
where even the keystroke count should stay unseen.

### Trying the console path by hand

The redirected path is covered by the test suite - for both features. So is
`read_masked_line`'s console path, headlessly, through a Windows
pseudoconsole (ConPTY) that opens no visible window: see
`testing/masked_line_conpty_test.py` (`pip install --user pywinpty` first).
`read_hidden_line`'s console path has no automated coverage at all: it needs
a real console, and a test runner's standard input is a file or a pipe. A
manual check for each feature ships with the test executable. Build it, then
run it from **cmd.exe or Windows Terminal** - not through a pipe, and not
from a mintty shell such as git-bash:

```
ec.sh test -config simple_console.ecf -target simple_console_tests
EIFGENs\simple_console_tests\F_code\simple_console.exe --hidden-line-demo
EIFGENs\simple_console_tests\F_code\simple_console.exe --masked-line-demo
```

What to look for, `--hidden-line-demo`:

1. `is_stdin_console` reports `True`.
2. Nothing appears on screen while you type the first line.
3. Backspace still erases, and Enter still ends the line.
4. The code points reported back are the ones you typed.
5. The second line, read the ordinary way, **does** echo - that is the proof
   the console mode was put back.

What to look for, `--masked-line-demo`:

1. `is_stdin_console` reports `True`.
2. Typing prints one `*` per character, immediately - never the character
   itself.
3. Backspace erases the last `*` printed and the character behind it, one
   pair at a time.
4. Enter ends the line and moves the cursor to a fresh line.
5. The code points reported back are the ones you typed - try a non-ASCII
   character, and Backspace right after it, if your keyboard can produce one.
6. The second line, read the ordinary way, **does** echo in full - that is
   the proof the console mode was put back.

### Color Constants

Black, Dark_blue, Dark_green, Dark_cyan, Dark_red, Dark_magenta, Dark_yellow, Gray, Dark_gray, Blue, Green, Cyan, Red, Magenta, Yellow, White (0-15)

## Documentation

- [API Documentation](https://simple-eiffel.github.io/simple_console/)

## Platform Support

- Windows only (uses Win32 API). The C layer carries a POSIX branch for
  parity, `read_hidden_line` and `read_masked_line` included, but it is not
  exercised.

## License

MIT License - see LICENSE file for details.

## Author

Larry Rix

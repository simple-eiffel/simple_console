# SIMPLE_CONSOLE

SCOOP-compatible console manipulation with colored text, cursor control, and screen operations.

## Features

- 16 foreground and background colors
- Cursor positioning and visibility control
- Screen and line clearing
- Console title setting
- Screen size detection
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

### Color Constants

Black, Dark_blue, Dark_green, Dark_cyan, Dark_red, Dark_magenta, Dark_yellow, Gray, Dark_gray, Blue, Green, Cyan, Red, Magenta, Yellow, White (0-15)

## Documentation

- [API Documentation](https://simple-eiffel.github.io/simple_console/)

## Platform Support

- Windows only (uses Win32 API)

## License

MIT License - see LICENSE file for details.

## Author

Larry Rix

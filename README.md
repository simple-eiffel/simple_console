<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# SIMPLE_CONSOLE

**[Documentation](https://simple-eiffel.github.io/simple_console/)**

### Console Manipulation Library for Eiffel

[![Language](https://img.shields.io/badge/language-Eiffel-blue.svg)](https://www.eiffel.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

---

## Overview

SIMPLE_CONSOLE provides SCOOP-compatible console manipulation for Eiffel applications. It wraps Win32 Console APIs through a clean C interface, enabling colored text output, cursor control, and screen operations without threading complications.

**Developed using AI-assisted methodology:** Built interactively with Claude Opus 4.5 following rigorous Design by Contract principles.

---

## Features

### Console Operations

- **Colors** - Set foreground/background colors (16 colors)
- **Cursor Control** - Position, show/hide cursor
- **Screen Operations** - Clear screen, clear line, get dimensions
- **Window Control** - Set console title
- **Convenience** - Print colored text, print at position

### Color Constants

| Color | Value | Color | Value |
|-------|-------|-------|-------|
| Black | 0 | Dark_gray | 8 |
| Dark_blue | 1 | Blue | 9 |
| Dark_green | 2 | Green | 10 |
| Dark_cyan | 3 | Cyan | 11 |
| Dark_red | 4 | Red | 12 |
| Dark_magenta | 5 | Magenta | 13 |
| Dark_yellow | 6 | Yellow | 14 |
| Gray | 7 | White | 15 |

---

## Quick Start

### Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_console.git
```

2. Compile the C library:
```bash
cd simple_console/Clib
compile.bat
```

3. Set the environment variable:
```bash
set SIMPLE_CONSOLE=D:\path\to\simple_console
```

4. Add to your ECF file:
```xml
<library name="simple_console" location="$SIMPLE_CONSOLE\simple_console.ecf"/>
```

### Basic Usage

```eiffel
class
    MY_APPLICATION

inherit
    SIMPLE_CONSOLE

feature

    console_example
        do
            -- Set window title
            set_title ("My Application")

            -- Clear screen
            clear

            -- Print colored text
            print_colored ("Error: ", Red)
            print ("Something went wrong%N")
            reset_color

            -- Print at specific position
            print_at ("Status: OK", 10, 5)

            -- Set colors manually
            set_foreground (Green)
            set_background (Black)
            print ("Green on black%N")
            reset_color

            -- Get console dimensions
            print ("Size: " + width.out + "x" + height.out + "%N")

            -- Cursor control
            hide_cursor
            set_cursor (0, 0)
            show_cursor
        end

end
```

---

## API Reference

### SIMPLE_CONSOLE Class

#### Colors

```eiffel
set_color (a_foreground, a_background: INTEGER)
    -- Set foreground and background colors.

set_foreground (a_color: INTEGER)
    -- Set foreground color only.

set_background (a_color: INTEGER)
    -- Set background color only.

reset_color
    -- Reset to default console colors.
```

#### Cursor Control

```eiffel
set_cursor (a_x, a_y: INTEGER)
    -- Move cursor to position (a_x, a_y). 0-based.

cursor_x: INTEGER
    -- Current cursor X position.

cursor_y: INTEGER
    -- Current cursor Y position.

show_cursor
    -- Make cursor visible.

hide_cursor
    -- Make cursor invisible.

is_cursor_visible: BOOLEAN
    -- Is the cursor currently visible?
```

#### Screen Information

```eiffel
width: INTEGER
    -- Console window width in characters.

height: INTEGER
    -- Console window height in characters.
```

#### Screen Operations

```eiffel
clear
    -- Clear the entire screen.

clear_line
    -- Clear from cursor to end of current line.

set_title (a_title: READABLE_STRING_GENERAL)
    -- Set console window title.
```

#### Convenience Methods

```eiffel
print_colored (a_text: READABLE_STRING_GENERAL; a_color: INTEGER)
    -- Print `a_text' in `a_color', then reset.

print_at (a_text: READABLE_STRING_GENERAL; a_x, a_y: INTEGER)
    -- Print `a_text' at position (a_x, a_y).
```

#### Status

```eiffel
last_operation_succeeded: BOOLEAN
    -- Did the last operation succeed?

has_real_console: BOOLEAN
    -- Do we have a real Windows console (not mintty/pipe)?
```

---

## Building & Testing

### Build Library

```bash
cd simple_console
ec -config simple_console.ecf -target simple_console -c_compile
```

### Run Tests

```bash
ec -config simple_console.ecf -target simple_console_tests -c_compile
./EIFGENs/simple_console_tests/W_code/simple_console.exe
```

---

## Project Structure

```
simple_console/
├── Clib/                       # C wrapper library
│   ├── simple_console.h        # C header file
│   ├── simple_console.c        # C implementation
│   └── compile.bat             # Build script
├── src/                        # Eiffel source
│   └── simple_console.e        # Main wrapper class
├── testing/                    # Test suite
│   ├── application.e           # Test runner
│   └── test_simple_console.e   # Test cases
├── simple_console.ecf          # Library configuration
├── README.md                   # This file
└── LICENSE                     # MIT License
```

---

## Dependencies

- **Windows OS** - Console API is Windows-specific
- **EiffelStudio 23.09+** - Development environment
- **Visual Studio C++ Build Tools** - For compiling C wrapper

---

## SCOOP Compatibility

SIMPLE_CONSOLE is fully SCOOP-compatible. The C wrapper handles all Win32 API calls synchronously without threading dependencies, making it safe for use in concurrent Eiffel applications.

**Note:** Console operations only work properly when `has_real_console` returns True. In mintty or piped output scenarios, some operations may not have visible effects.

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Contact

- **Author:** Larry Rix
- **Repository:** https://github.com/simple-eiffel/simple_console
- **Issues:** https://github.com/simple-eiffel/simple_console/issues

---

## Acknowledgments

- Built with Claude Opus 4.5 (Anthropic)
- Uses Win32 Console API (Microsoft)
- Part of the simple_ library collection for Eiffel

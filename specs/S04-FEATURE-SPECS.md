# S04: FEATURE SPECS - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Feature Specifications

### Color Operations

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_color | (fg, bg: INTEGER) | Set both colors |
| set_foreground | (color: INTEGER) | Set foreground only |
| set_background | (color: INTEGER) | Set background only |
| reset_color | | Reset to gray on black |

### Cursor Control

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_cursor | (x, y: INTEGER) | Move cursor (0-based) |
| cursor_x | : INTEGER | Current X position |
| cursor_y | : INTEGER | Current Y position |
| show_cursor | | Make cursor visible |
| hide_cursor | | Make cursor invisible |
| is_cursor_visible | : BOOLEAN | Is visible? |

### Screen Information

| Feature | Signature | Description |
|---------|-----------|-------------|
| width | : INTEGER | Console width |
| height | : INTEGER | Console height |

### Screen Operations

| Feature | Signature | Description |
|---------|-----------|-------------|
| clear | | Clear screen, cursor to (0,0) |
| clear_line | | Clear from cursor to EOL |
| set_title | (title: STRING) | Set window title |

### Convenience Output

| Feature | Signature | Description |
|---------|-----------|-------------|
| print_colored | (text: STRING; color: INTEGER) | Print with color |
| print_at | (text: STRING; x, y: INTEGER) | Print at position |
| print_line | (text: STRING) | Print with newline |
| print_success | (text: STRING) | Green, with newline |
| print_error | (text: STRING) | Red, with newline |
| print_warning | (text: STRING) | Yellow, with newline |
| print_info | (text: STRING) | Cyan, with newline |

### Status

| Feature | Signature | Description |
|---------|-----------|-------------|
| last_operation_succeeded | : BOOLEAN | Last op OK? |
| last_error_message | : STRING | Error description |
| has_real_console | : BOOLEAN | Not mintty/pipe? |

### Logging

| Feature | Signature | Description |
|---------|-----------|-------------|
| enable_logging | | Enable logging |
| disable_logging | | Disable logging |
| is_logging_enabled | : BOOLEAN | Logging on? |
| set_log_level | (level: INTEGER) | Set min level |

### Color Constants

| Constant | Value | Constant | Value |
|----------|-------|----------|-------|
| Black | 0 | Dark_gray | 8 |
| Dark_blue | 1 | Blue | 9 |
| Dark_green | 2 | Green | 10 |
| Dark_cyan | 3 | Cyan | 11 |
| Dark_red | 4 | Red | 12 |
| Dark_magenta | 5 | Magenta | 13 |
| Dark_yellow | 6 | Yellow | 14 |
| Gray | 7 | White | 15 |

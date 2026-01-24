# S02: CLASS CATALOG - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Class Hierarchy

```
SIMPLE_CONSOLE
    |
    +-- inherits --> ANY (override default_create)
    |
    +-- optionally uses --> SIMPLE_LOGGER
```

## Class Description

### SIMPLE_CONSOLE
**Purpose:** SCOOP-compatible console manipulation
**Role:** Provide colored output, cursor control, screen management
**Key Features:**

#### Colors
- `set_color` - Set foreground and background
- `set_foreground` - Set foreground only
- `set_background` - Set background only
- `reset_color` - Reset to defaults

#### Cursor Control
- `set_cursor` - Move cursor to position
- `cursor_x`, `cursor_y` - Get current position
- `show_cursor`, `hide_cursor` - Visibility
- `is_cursor_visible` - Query visibility

#### Screen Information
- `width`, `height` - Console dimensions

#### Screen Operations
- `clear` - Clear entire screen
- `clear_line` - Clear current line
- `set_title` - Set window title

#### Convenience Output
- `print_colored` - Print with color, reset
- `print_at` - Print at position
- `print_line` - Print with newline
- `print_success` - Green text
- `print_error` - Red text
- `print_warning` - Yellow text
- `print_info` - Cyan text

#### Status
- `last_operation_succeeded` - Operation status
- `last_error_message` - Error description
- `has_real_console` - Real console check

#### Logging
- `enable_logging`, `disable_logging` - Toggle
- `is_logging_enabled` - Query
- `set_log_level` - Set minimum level
- Log level constants

#### Color Constants
- Black through White (16 colors)
- `is_valid_color` - Validation
- `color_name` - Human-readable name

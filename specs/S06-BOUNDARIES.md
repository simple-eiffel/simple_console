# S06: BOUNDARIES - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## API Boundaries

### Public Interface

#### Initialization
- `make`, `default_create`

#### Colors
- `set_color`, `set_foreground`, `set_background`
- `reset_color`
- `is_valid_color`, `color_name`
- Color constants (Black through White)

#### Cursor
- `set_cursor`, `cursor_x`, `cursor_y`
- `show_cursor`, `hide_cursor`, `is_cursor_visible`

#### Screen
- `width`, `height`
- `clear`, `clear_line`
- `set_title`

#### Output Helpers
- `print_colored`, `print_at`, `print_line`
- `print_success`, `print_error`, `print_warning`, `print_info`

#### Status
- `last_operation_succeeded`, `last_error_message`
- `has_real_console`

#### Logging
- `enable_logging`, `disable_logging`, `is_logging_enabled`
- `set_log_level`, `log_level`, `logger`
- Log level constants

### Internal Interface (NONE)

- `c_sc_*` - All C external functions
- `log_debug`, `log_info`, `log_error` - Internal logging
- `Color_nibble_shift`, `Max_color_value` - Constants

## Integration Points

| Component | Interface | Direction |
|-----------|-----------|-----------|
| Win32 API | C inline | Outbound |
| SIMPLE_LOGGER | Library | Outbound |
| Console | Hardware | Both |
| Caller code | Public API | Inbound |

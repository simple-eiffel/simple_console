# S03: CONTRACTS - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Design by Contract Summary

### SIMPLE_CONSOLE Contracts

#### make
```eiffel
ensure
    no_error: last_error_message.is_empty
    logging_disabled: not is_logging_enabled
```

#### set_color
```eiffel
require
    valid_foreground: is_valid_color (a_foreground)
    valid_background: is_valid_color (a_background)
ensure
    error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
    error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
```

#### set_cursor
```eiffel
require
    valid_x: a_x >= 0
    valid_y: a_y >= 0
    x_in_bounds: has_real_console implies a_x < width
    y_in_bounds: has_real_console implies a_y < height
ensure
    cursor_x_set: last_operation_succeeded implies cursor_x = a_x
    cursor_y_set: last_operation_succeeded implies cursor_y = a_y
```

#### show_cursor
```eiffel
ensure
    cursor_visible: last_operation_succeeded implies is_cursor_visible
```

#### hide_cursor
```eiffel
ensure
    cursor_hidden: last_operation_succeeded implies not is_cursor_visible
```

#### clear
```eiffel
ensure
    cursor_at_home: last_operation_succeeded implies (cursor_x = 0 and cursor_y = 0)
```

#### set_title
```eiffel
require
    title_not_void: a_title /= Void
    title_not_empty: not a_title.is_empty
```

#### set_log_level
```eiffel
require
    valid_level: a_level >= Log_level_debug and a_level <= Log_level_fatal
ensure
    level_set: log_level = a_level
```

### Class Invariant
```eiffel
invariant
    error_message_not_void: last_error_message /= Void
    color_constants_valid: Black = 0 and White = Max_color_value
    log_level_valid: log_level >= 0 and log_level <= Log_level_fatal
```

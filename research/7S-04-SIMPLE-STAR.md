# 7S-04: SIMPLE-STAR - simple_console


**Date**: 2026-01-23

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Ecosystem Integration

### Dependencies on Other simple_* Libraries
- **simple_logger** (optional) - Structured logging of console operations

### Libraries That May Depend on simple_console
- **simple_cli** - CLI application framework
- **simple_ci** - Build output with colors
- **simple_test** - Test result display
- **simple_progress** - Progress bars and spinners

### Integration Patterns

#### Basic colored output
```eiffel
local
    console: SIMPLE_CONSOLE
do
    create console.make
    console.set_foreground (console.Green)
    print ("Success!")
    console.reset_color
end
```

#### Using helper methods
```eiffel
console.print_success ("Build completed")
console.print_error ("Compilation failed")
console.print_warning ("Deprecated API")
console.print_info ("Processing file...")
```

#### With logging
```eiffel
console.enable_logging
console.set_log_level (console.Log_level_debug)
-- All operations now logged
console.set_foreground (console.Red) -- Logged
```

## Namespace Conventions
- Single class: SIMPLE_CONSOLE
- C header: simple_console.h
- C functions: sc_* prefix
- Color constants: Direct names (Red, Green, etc.)

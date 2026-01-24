# S05: CONSTRAINTS - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Technical Constraints

### 1. Windows Only
- **Constraint:** Uses Win32 Console API
- **Impact:** Not portable to Unix/Mac
- **Mitigation:** Could add ANSI fallback

### 2. 16 Colors Only
- **Constraint:** Traditional console colors (0-15)
- **Impact:** No 256-color or true color
- **Mitigation:** Sufficient for most CLI apps

### 3. Real Console Required
- **Constraint:** Some operations fail without real console
- **Impact:** mintty, pipes, IDEs may not support all features
- **Mitigation:** has_real_console check

### 4. Coordinate Bounds
- **Constraint:** Cursor position must be within console
- **Impact:** set_cursor may fail for invalid positions
- **Mitigation:** Bounds checked in preconditions

### 5. Title Length
- **Constraint:** Windows title length limit
- **Impact:** Very long titles truncated
- **Mitigation:** Keep titles reasonable

## Resource Limits

| Resource | Limit | Notes |
|----------|-------|-------|
| Colors | 16 | 0-15 values |
| X position | width-1 | 0-based |
| Y position | height-1 | 0-based |

## Performance Constraints

| Operation | Expected Time |
|-----------|---------------|
| set_color | < 1ms |
| set_cursor | < 1ms |
| clear | < 10ms |
| All operations | Synchronous |

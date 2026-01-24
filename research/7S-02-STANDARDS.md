# 7S-02: STANDARDS - simple_console


**Date**: 2026-01-23

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Applicable Standards

### Windows Console API
- GetStdHandle - Obtain console handles
- SetConsoleTextAttribute - Set colors
- SetConsoleCursorPosition - Move cursor
- GetConsoleScreenBufferInfo - Query state
- SetConsoleCursorInfo - Cursor visibility
- FillConsoleOutputCharacter - Clear operations
- SetConsoleTitle - Window title

### Color Values (4-bit)
Low nibble = foreground, high nibble = background

| Value | Color |
|-------|-------|
| 0 | Black |
| 1 | Dark Blue |
| 2 | Dark Green |
| 3 | Dark Cyan |
| 4 | Dark Red |
| 5 | Dark Magenta |
| 6 | Dark Yellow |
| 7 | Gray |
| 8 | Dark Gray |
| 9 | Blue |
| 10 | Green |
| 11 | Cyan |
| 12 | Red |
| 13 | Magenta |
| 14 | Yellow |
| 15 | White |

### Coordinate System
- (0,0) is top-left corner
- X increases to the right
- Y increases downward

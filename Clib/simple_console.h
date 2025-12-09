/*
 * simple_console.h - Windows Console helper functions for Eiffel
 */

#ifndef SIMPLE_CONSOLE_H
#define SIMPLE_CONSOLE_H

#include <windows.h>

static int sc_set_color(int color) {
    return SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), (WORD)color) ? 1 : 0;
}

static int sc_set_foreground(int color) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!GetConsoleScreenBufferInfo(h, &csbi)) return 0;
    return SetConsoleTextAttribute(h, (csbi.wAttributes & 0xF0) | (color & 0x0F)) ? 1 : 0;
}

static int sc_set_background(int color) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!GetConsoleScreenBufferInfo(h, &csbi)) return 0;
    return SetConsoleTextAttribute(h, (csbi.wAttributes & 0x0F) | ((color & 0x0F) << 4)) ? 1 : 0;
}

static int sc_reset_color(void) {
    return SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7) ? 1 : 0;
}

static int sc_set_cursor(int x, int y) {
    COORD pos; pos.X = (SHORT)x; pos.Y = (SHORT)y;
    return SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), pos) ? 1 : 0;
}

static int sc_get_cursor_x(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)) return -1;
    return (int)csbi.dwCursorPosition.X;
}

static int sc_get_cursor_y(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)) return -1;
    return (int)csbi.dwCursorPosition.Y;
}

static int sc_get_width(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)) return 80;
    return (int)(csbi.srWindow.Right - csbi.srWindow.Left + 1);
}

static int sc_get_height(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)) return 25;
    return (int)(csbi.srWindow.Bottom - csbi.srWindow.Top + 1);
}

static int sc_clear(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD written;
    COORD home = {0, 0};
    DWORD size;
    if (!GetConsoleScreenBufferInfo(h, &csbi)) return 0;
    size = csbi.dwSize.X * csbi.dwSize.Y;
    FillConsoleOutputCharacterA(h, 32, size, home, &written);
    FillConsoleOutputAttribute(h, csbi.wAttributes, size, home, &written);
    SetConsoleCursorPosition(h, home);
    return 1;
}

static int sc_clear_line(void) {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD written;
    DWORD len;
    if (!GetConsoleScreenBufferInfo(h, &csbi)) return 0;
    len = csbi.dwSize.X - csbi.dwCursorPosition.X;
    FillConsoleOutputCharacterA(h, 32, len, csbi.dwCursorPosition, &written);
    FillConsoleOutputAttribute(h, csbi.wAttributes, len, csbi.dwCursorPosition, &written);
    return 1;
}

static int sc_set_title(const char* title) {
    return SetConsoleTitleA(title) ? 1 : 0;
}

static int sc_show_cursor(int visible) {
    CONSOLE_CURSOR_INFO cci;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!GetConsoleCursorInfo(h, &cci)) return 0;
    cci.bVisible = visible ? TRUE : FALSE;
    return SetConsoleCursorInfo(h, &cci) ? 1 : 0;
}

static int sc_is_cursor_visible(void) {
    CONSOLE_CURSOR_INFO cci;
    if (!GetConsoleCursorInfo(GetStdHandle(STD_OUTPUT_HANDLE), &cci)) return 1;
    return cci.bVisible ? 1 : 0;
}

static int sc_has_real_console(void) {
    DWORD mode;
    HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
    if (h == INVALID_HANDLE_VALUE || h == NULL) return 0;
    return GetConsoleMode(h, &mode) ? 1 : 0;
}

#endif /* SIMPLE_CONSOLE_H */

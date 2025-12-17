/*
 * simple_console.h - Cross-platform Console helper functions for Eiffel
 *
 * Windows: Uses Win32 Console API
 * Linux/macOS: Uses ANSI escape sequences
 *
 * Copyright (c) 2025 Larry Rix - MIT License
 */

#ifndef SIMPLE_CONSOLE_H
#define SIMPLE_CONSOLE_H

#if defined(_WIN32) || defined(EIF_WINDOWS)
/* ============ WINDOWS IMPLEMENTATION ============ */

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

#else
/* ============ UNIX/LINUX IMPLEMENTATION ============ */
/* Uses ANSI escape sequences for terminal control */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <string.h>

/* Track current state for queries */
static int sc_current_fg = 7;  /* Default: gray */
static int sc_current_bg = 0;  /* Default: black */
static int sc_cursor_visible = 1;
static int sc_cursor_x = 0;
static int sc_cursor_y = 0;

/* Map Windows color codes (0-15) to ANSI SGR codes */
/* Windows: 0=Black,1=DarkBlue,2=DarkGreen,3=DarkCyan,4=DarkRed,5=DarkMagenta,
            6=DarkYellow,7=Gray,8=DarkGray,9=Blue,10=Green,11=Cyan,12=Red,
            13=Magenta,14=Yellow,15=White */
static const int sc_win_to_ansi_fg[] = {
    30, 34, 32, 36, 31, 35, 33, 37,  /* 0-7: dark colors */
    90, 94, 92, 96, 91, 95, 93, 97   /* 8-15: bright colors */
};
static const int sc_win_to_ansi_bg[] = {
    40, 44, 42, 46, 41, 45, 43, 47,  /* 0-7: dark backgrounds */
    100, 104, 102, 106, 101, 105, 103, 107  /* 8-15: bright backgrounds */
};

static int sc_set_color(int color) {
    int fg = color & 0x0F;
    int bg = (color >> 4) & 0x0F;
    sc_current_fg = fg;
    sc_current_bg = bg;
    printf("\033[%d;%dm", sc_win_to_ansi_fg[fg], sc_win_to_ansi_bg[bg]);
    fflush(stdout);
    return 1;
}

static int sc_set_foreground(int color) {
    if (color < 0 || color > 15) return 0;
    sc_current_fg = color;
    printf("\033[%dm", sc_win_to_ansi_fg[color]);
    fflush(stdout);
    return 1;
}

static int sc_set_background(int color) {
    if (color < 0 || color > 15) return 0;
    sc_current_bg = color;
    printf("\033[%dm", sc_win_to_ansi_bg[color]);
    fflush(stdout);
    return 1;
}

static int sc_reset_color(void) {
    sc_current_fg = 7;
    sc_current_bg = 0;
    printf("\033[0m");
    fflush(stdout);
    return 1;
}

static int sc_set_cursor(int x, int y) {
    sc_cursor_x = x;
    sc_cursor_y = y;
    /* ANSI is 1-based, our API is 0-based */
    printf("\033[%d;%dH", y + 1, x + 1);
    fflush(stdout);
    return 1;
}

static int sc_get_cursor_x(void) {
    return sc_cursor_x;
}

static int sc_get_cursor_y(void) {
    return sc_cursor_y;
}

static int sc_get_width(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_col > 0) {
        return ws.ws_col;
    }
    /* Fallback: check COLUMNS env var */
    char* cols = getenv("COLUMNS");
    if (cols) return atoi(cols);
    return 80;
}

static int sc_get_height(void) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 && ws.ws_row > 0) {
        return ws.ws_row;
    }
    /* Fallback: check LINES env var */
    char* lines = getenv("LINES");
    if (lines) return atoi(lines);
    return 25;
}

static int sc_clear(void) {
    /* Clear screen and move cursor to home */
    printf("\033[2J\033[H");
    fflush(stdout);
    sc_cursor_x = 0;
    sc_cursor_y = 0;
    return 1;
}

static int sc_clear_line(void) {
    /* Clear from cursor to end of line */
    printf("\033[K");
    fflush(stdout);
    return 1;
}

static int sc_set_title(const char* title) {
    /* OSC sequence to set terminal title */
    printf("\033]0;%s\007", title);
    fflush(stdout);
    return 1;
}

static int sc_show_cursor(int visible) {
    sc_cursor_visible = visible;
    if (visible) {
        printf("\033[?25h");  /* Show cursor */
    } else {
        printf("\033[?25l");  /* Hide cursor */
    }
    fflush(stdout);
    return 1;
}

static int sc_is_cursor_visible(void) {
    return sc_cursor_visible;
}

static int sc_has_real_console(void) {
    /* Check if stdout is a terminal */
    return isatty(STDOUT_FILENO) ? 1 : 0;
}

#endif /* _WIN32 */

#endif /* SIMPLE_CONSOLE_H */

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

/* Key reading with modifier detection */
static int sc_last_char = 0;
static int sc_last_shift = 0;
static int sc_last_ctrl = 0;
static int sc_last_is_enter = 0;
static int sc_last_is_backspace = 0;

static int sc_read_key(void) {
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    INPUT_RECORD ir;
    DWORD numRead;
    DWORD oldMode;

    if (hStdin == INVALID_HANDLE_VALUE) return 0;

    /* Save and modify console mode for raw input */
    GetConsoleMode(hStdin, &oldMode);
    SetConsoleMode(hStdin, oldMode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT));

    /* Read until we get a key down event */
    while (1) {
        if (!ReadConsoleInputW(hStdin, &ir, 1, &numRead) || numRead == 0) {
            SetConsoleMode(hStdin, oldMode);
            return 0;
        }

        if (ir.EventType == KEY_EVENT && ir.Event.KeyEvent.bKeyDown) {
            WORD vk = ir.Event.KeyEvent.wVirtualKeyCode;
            DWORD ctrl = ir.Event.KeyEvent.dwControlKeyState;
            WCHAR ch = ir.Event.KeyEvent.uChar.UnicodeChar;

            sc_last_shift = (ctrl & SHIFT_PRESSED) ? 1 : 0;
            sc_last_ctrl = (ctrl & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) ? 1 : 0;
            sc_last_is_enter = (vk == VK_RETURN) ? 1 : 0;
            sc_last_is_backspace = (vk == VK_BACK) ? 1 : 0;

            if (ch != 0 && ch < 256) {
                sc_last_char = (int)ch;
            } else {
                sc_last_char = 0;
            }

            SetConsoleMode(hStdin, oldMode);
            return 1;
        }
    }
}

static int sc_get_last_char(void) { return sc_last_char; }
static int sc_get_last_shift(void) { return sc_last_shift; }
static int sc_get_last_ctrl(void) { return sc_last_ctrl; }
static int sc_get_last_is_enter(void) { return sc_last_is_enter; }
static int sc_get_last_is_backspace(void) { return sc_last_is_backspace; }

static int sc_has_pending_input(void) {
    /* Check if more input is waiting (for paste detection) */
    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    DWORD numEvents = 0;
    if (!GetNumberOfConsoleInputEvents(hStdin, &numEvents)) return 0;
    /* More than 0 events means input is pending */
    return (numEvents > 0) ? 1 : 0;
}

/* ============ HIDDEN (NO-ECHO) LINE INPUT ============
 *
 * sc_is_stdin_console  - is STDIN a real console, not a file or a pipe?
 * sc_read_hidden_line  - read ONE line from the console with echo off.
 *
 * The whole mode dance lives inside sc_read_hidden_line, in C, so that the
 * caller's console mode is restored on EVERY exit path. A console left
 * without ENABLE_ECHO_INPUT is a console the user cannot see themselves
 * type in again, for the rest of the session - so the restore must not be
 * reachable only through a happy path, and must not depend on an Eiffel
 * rescue clause running.
 */

static int sc_is_stdin_console(void) {
    DWORD mode;
    HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
    if (h == INVALID_HANDLE_VALUE || h == NULL) return 0;
    return GetConsoleMode(h, &mode) ? 1 : 0;
}

/* Read one line from the console into a_buffer with echo suppressed.
 *
 * a_buffer   - caller-owned buffer of a_capacity UTF-16 code units. It must
 *              NOT be Eiffel-collected memory: the Eiffel wrapper marks its
 *              external `blocking', so a collection may run - and move
 *              objects - while this function is still waiting on the user.
 * a_capacity - code units including room for the terminating NUL.
 *
 * Returns the number of code units stored, with the trailing CR / LF
 * stripped and a NUL written after them; 0 for a line the user just pressed
 * Enter on. Returns -1 on end-of-input (Ctrl+Z), on a read error, or when
 * STDIN is not a console - and in that case stores nothing, so a caller can
 * never mistake a partial read for a line.
 */
static int sc_read_hidden_line(void* a_buffer, int a_capacity) {
    HANDLE h;
    DWORD old_mode = 0;
    DWORD units_read = 0;
    int n;
    BOOL ok;
    WCHAR* buf = (WCHAR*)a_buffer;

    if (buf == NULL || a_capacity <= 1) return -1;
    buf[0] = 0;

    h = GetStdHandle(STD_INPUT_HANDLE);
    if (h == INVALID_HANDLE_VALUE || h == NULL) return -1;

    /* GetConsoleMode fails on a redirected handle: that case belongs to the
       caller's plain-line path, not here. */
    if (!GetConsoleMode(h, &old_mode)) return -1;

    /* Clear ONLY the echo. ENABLE_LINE_INPUT stays, so Backspace still
       edits the line and Enter still ends it; ENABLE_PROCESSED_INPUT stays,
       so Ctrl+C still reaches the process. */
    if (!SetConsoleMode(h, old_mode & ~((DWORD)ENABLE_ECHO_INPUT))) return -1;

    ok = ReadConsoleW(h, buf, (DWORD)(a_capacity - 1), &units_read, NULL);

    /* ALWAYS restore - success or failure, before anything else is decided. */
    SetConsoleMode(h, old_mode);

    if (!ok || units_read == 0) {
        buf[0] = 0;
        return -1;
    }

    n = (int)units_read;
    while (n > 0 && (buf[n - 1] == L'\n' || buf[n - 1] == L'\r')) n--;
    buf[n] = 0;
    return n;
}

/* ============ MASKED (VISIBLE-DOTS) LINE INPUT ============
 *
 * sc_read_masked_line - like sc_read_hidden_line, but prints one copy of a
 * caller-chosen mask character for every character accepted, so the typist
 * can see their keystrokes are registering without the console ever
 * showing what was typed. Added after Larry used 1.1.0's fully-silent
 * `read_hidden_line' in an installer console: "I was surprised by not even
 * have dots for pw chars. That meant that I didn't know whether my
 * keystrokes were being registered. So, the dots would really help."
 *
 * `sc_read_hidden_line' hands the whole job to ReadConsoleW with only
 * ENABLE_ECHO_INPUT cleared, so Windows' own line editor still does
 * Backspace and Enter for it. This function cannot do that - Windows has no
 * mode that echoes a substitute character - so it clears ENABLE_LINE_INPUT
 * too and becomes the line editor itself, reading one key event at a time
 * with ReadConsoleInputW the way `sc_read_key' above does for a single key.
 * It is deliberately the ONLY place that decides what counts as a
 * character, what Backspace erases, and when the line ends - the same
 * restore-on-every-exit-path discipline as `sc_read_hidden_line', for the
 * same reason: a console left without its saved mode is one the user
 * cannot see themselves type into again for the rest of the session.
 *
 * a_buffer    - caller-owned buffer of a_capacity UTF-16 code units. Must be
 *               C heap (a MANAGED_POINTER on the Eiffel side), never the
 *               `base_address' of an Eiffel SPECIAL: this external is
 *               marked `C blocking' because it waits on the user, which
 *               lets a garbage collection run - and move Eiffel objects -
 *               while this function still holds the address.
 * a_capacity  - code units, including room for the terminating NUL.
 * a_mask_cp   - Unicode code point printed once per accepted character.
 *
 * Returns the number of UTF-16 code units stored (0 for Enter pressed
 * immediately, no CR/LF among them); -1 on a read error or when STDIN is
 * not a console - `a_buffer' is left holding nothing on that path, so a
 * caller can never mistake a partial line for a whole one.
 *
 * A surrogate pair (a character outside the Basic Multilingual Plane - most
 * emoji, for instance) is two UTF-16 code units but ONE accepted character:
 * one mask is printed for the pair, and one Backspace erases both units and
 * the one mask together. ENABLE_PROCESSED_INPUT is left exactly as
 * `GetConsoleMode' found it, so Ctrl+C keeps working precisely the way it
 * does for `sc_read_hidden_line'.
 */
static int sc_read_masked_line(void* a_buffer, int a_capacity, unsigned int a_mask_cp) {
    HANDLE hIn, hOut;
    DWORD old_mode = 0;
    DWORD num_read = 0;
    DWORD written = 0;
    INPUT_RECORD ir;
    WCHAR* buf = (WCHAR*)a_buffer;
    WCHAR mask_units[2];
    int mask_len;
    int count = 0;
    WCHAR pending_high = 0;
    BOOL done = FALSE;
    BOOL failed = FALSE;

    if (buf == NULL || a_capacity <= 1) return -1;
    buf[0] = 0;

    hIn = GetStdHandle(STD_INPUT_HANDLE);
    if (hIn == INVALID_HANDLE_VALUE || hIn == NULL) return -1;

    /* GetConsoleMode fails on a redirected handle: that case belongs to the
       caller's plain-line path, not here. */
    if (!GetConsoleMode(hIn, &old_mode)) return -1;

    hOut = GetStdHandle(STD_OUTPUT_HANDLE);

    /* Encode the mask character to UTF-16 once, outside the key loop. */
    if (a_mask_cp >= 0x10000 && a_mask_cp <= 0x10FFFF) {
        unsigned int v = a_mask_cp - 0x10000;
        mask_units[0] = (WCHAR)(0xD800 + (v >> 10));
        mask_units[1] = (WCHAR)(0xDC00 + (v & 0x3FF));
        mask_len = 2;
    } else {
        mask_units[0] = (WCHAR)a_mask_cp;
        mask_len = 1;
    }

    /* Clear line editing and echo; every other bit - ENABLE_PROCESSED_INPUT
       included - is carried over unchanged from the mode we just read. */
    if (!SetConsoleMode(hIn, old_mode & ~((DWORD)(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT)))) {
        return -1;
    }

    while (!done && !failed) {
        if (!ReadConsoleInputW(hIn, &ir, 1, &num_read) || num_read == 0) {
            failed = TRUE;
        } else if (ir.EventType == KEY_EVENT && ir.Event.KeyEvent.bKeyDown) {
            WORD vk = ir.Event.KeyEvent.wVirtualKeyCode;
            WCHAR ch = ir.Event.KeyEvent.uChar.UnicodeChar;

            if (vk == VK_RETURN) {
                if (hOut != INVALID_HANDLE_VALUE) {
                    WriteConsoleW(hOut, L"\r\n", 2, &written, NULL);
                }
                done = TRUE;
            } else if (vk == VK_BACK) {
                if (count > 0) {
                    if (count >= 2 && buf[count - 1] >= 0xDC00 && buf[count - 1] <= 0xDFFF &&
                        buf[count - 2] >= 0xD800 && buf[count - 2] <= 0xDBFF) {
                        count -= 2;
                    } else {
                        count -= 1;
                    }
                    buf[count] = 0;
                    if (hOut != INVALID_HANDLE_VALUE) {
                        WriteConsoleW(hOut, L"\b \b", 3, &written, NULL);
                    }
                }
                pending_high = 0;   /* Backspace also cancels a lone pending high surrogate. */
            } else if (ch == 0 || ch < 0x20 || ch == 0x7F) {
                /* Not a character: arrow/function/modifier keys read as
                   ch == 0; Tab, Esc, Ctrl+letter and friends read as other
                   control codes below 0x20, or DEL. None are accepted. */
            } else if (ch >= 0xD800 && ch <= 0xDBFF) {
                pending_high = ch;   /* High surrogate: wait for its low half. */
            } else if (ch >= 0xDC00 && ch <= 0xDFFF) {
                if (pending_high != 0 && count + 2 <= a_capacity - 1) {
                    buf[count++] = pending_high;
                    buf[count++] = ch;
                    buf[count] = 0;
                    if (hOut != INVALID_HANDLE_VALUE) {
                        WriteConsoleW(hOut, mask_units, (DWORD)mask_len, &written, NULL);
                    }
                }
                pending_high = 0;   /* Paired, dropped for overflow, or unpaired: clear either way. */
            } else {
                /* An ordinary BMP character. A stray pending high surrogate
                   with no low surrogate behind it was malformed input;
                   drop it rather than pairing it with something unrelated. */
                pending_high = 0;
                if (count + 1 <= a_capacity - 1) {
                    buf[count++] = ch;
                    buf[count] = 0;
                    if (hOut != INVALID_HANDLE_VALUE) {
                        WriteConsoleW(hOut, mask_units, (DWORD)mask_len, &written, NULL);
                    }
                }
            }
        }
        /* Any other event type (mouse, window-buffer-size, focus) or a
           key-up event: read the next one. */
    }

    /* ALWAYS restore - success or failure, before anything else is decided. */
    SetConsoleMode(hIn, old_mode);

    if (failed) {
        buf[0] = 0;
        return -1;
    }
    return count;
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

/* ============ HIDDEN (NO-ECHO) LINE INPUT ============
 *
 * POSIX parity for the Windows routines of the same names. Same contract,
 * same restore-always discipline (termios instead of console modes), and
 * the same UTF-16 output buffer, so the Eiffel side decodes one encoding on
 * every platform.
 *
 * NOTE: simple_console ships and is exercised on Windows. This branch is
 * written for parity and has not been run.
 */

static int sc_is_stdin_console(void) {
    return isatty(STDIN_FILENO) ? 1 : 0;
}

static int sc_read_hidden_line(void* a_buffer, int a_capacity) {
    unsigned short* out = (unsigned short*)a_buffer;
    struct termios old_t, new_t;
    unsigned char bytes[4096];
    int len = 0, i = 0, n = 0;
    ssize_t got = 0;

    if (out == NULL || a_capacity <= 2) return -1;
    out[0] = 0;

    if (!isatty(STDIN_FILENO)) return -1;
    if (tcgetattr(STDIN_FILENO, &old_t) != 0) return -1;

    new_t = old_t;
    new_t.c_lflag &= ~ECHO;   /* ICANON stays: Backspace still edits the line */
    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &new_t) != 0) return -1;

    while (len < (int)sizeof(bytes)) {
        got = read(STDIN_FILENO, bytes + len, 1);
        if (got <= 0) break;
        if (bytes[len] == '\n') break;
        len++;
    }

    /* ALWAYS restore. */
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &old_t);

    if (len == 0 && got <= 0) {
        out[0] = 0;
        return -1;   /* end of input */
    }

    while (len > 0 && (bytes[len - 1] == '\r' || bytes[len - 1] == '\n')) len--;

    /* UTF-8 in, UTF-16 out. */
    while (i < len && n < a_capacity - 2) {
        unsigned int cp = bytes[i];
        int extra;
        if (cp < 0x80)                 { extra = 0; }
        else if ((cp & 0xE0) == 0xC0)  { cp &= 0x1F; extra = 1; }
        else if ((cp & 0xF0) == 0xE0)  { cp &= 0x0F; extra = 2; }
        else if ((cp & 0xF8) == 0xF0)  { cp &= 0x07; extra = 3; }
        else                           { cp = 0xFFFD; extra = 0; }
        i++;
        while (extra > 0 && i < len && (bytes[i] & 0xC0) == 0x80) {
            cp = (cp << 6) | (unsigned int)(bytes[i] & 0x3F);
            i++; extra--;
        }
        if (extra != 0) cp = 0xFFFD;
        if (cp >= 0x10000 && cp <= 0x10FFFF) {
            cp -= 0x10000;
            out[n++] = (unsigned short)(0xD800 + (cp >> 10));
            out[n++] = (unsigned short)(0xDC00 + (cp & 0x3FF));
        } else {
            out[n++] = (unsigned short)cp;
        }
    }
    out[n] = 0;

    memset(bytes, 0, sizeof(bytes));   /* it held the secret */
    return n;
}

/* POSIX parity for `sc_read_masked_line'. Same contract: one mask per
 * accepted character, Backspace erases the last character AND its one
 * on-screen mask, Enter ends the line. ICANON is cleared as well as ECHO -
 * unlike `sc_read_hidden_line' above, which needs only ECHO off because
 * Windows' own line editor keeps working underneath it, this function must
 * become the line editor itself, one byte at a time, the same way its
 * Windows counterpart becomes one event at a time. ISIG is left alone, so
 * Ctrl+C keeps working.
 *
 * NOTE: simple_console ships and is exercised on Windows. This branch is
 * written for parity and has not been run.
 */
static int sc_read_masked_line(void* a_buffer, int a_capacity, unsigned int a_mask_cp) {
    unsigned short* out = (unsigned short*)a_buffer;
    struct termios old_t, new_t;
    unsigned char mask_utf8[4];
    int mask_utf8_len;
    int n = 0;              /* UTF-16 code units stored in `out' so far */
    int done = 0;
    ssize_t got;
    unsigned char b;

    if (out == NULL || a_capacity <= 2) return -1;
    out[0] = 0;

    if (!isatty(STDIN_FILENO)) return -1;
    if (tcgetattr(STDIN_FILENO, &old_t) != 0) return -1;

    new_t = old_t;
    new_t.c_lflag &= ~((tcflag_t)(ECHO | ICANON));   /* ISIG stays: Ctrl+C still works. */
    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &new_t) != 0) return -1;

    /* Encode the mask code point to UTF-8 once, outside the read loop. */
    if (a_mask_cp < 0x80) {
        mask_utf8[0] = (unsigned char)a_mask_cp;
        mask_utf8_len = 1;
    } else if (a_mask_cp < 0x800) {
        mask_utf8[0] = (unsigned char)(0xC0 | (a_mask_cp >> 6));
        mask_utf8[1] = (unsigned char)(0x80 | (a_mask_cp & 0x3F));
        mask_utf8_len = 2;
    } else if (a_mask_cp < 0x10000) {
        mask_utf8[0] = (unsigned char)(0xE0 | (a_mask_cp >> 12));
        mask_utf8[1] = (unsigned char)(0x80 | ((a_mask_cp >> 6) & 0x3F));
        mask_utf8[2] = (unsigned char)(0x80 | (a_mask_cp & 0x3F));
        mask_utf8_len = 3;
    } else {
        mask_utf8[0] = (unsigned char)(0xF0 | (a_mask_cp >> 18));
        mask_utf8[1] = (unsigned char)(0x80 | ((a_mask_cp >> 12) & 0x3F));
        mask_utf8[2] = (unsigned char)(0x80 | ((a_mask_cp >> 6) & 0x3F));
        mask_utf8[3] = (unsigned char)(0x80 | (a_mask_cp & 0x3F));
        mask_utf8_len = 4;
    }

    while (!done) {
        got = read(STDIN_FILENO, &b, 1);
        if (got <= 0) {
            done = 1;
            n = -1;   /* end of input or a read error: never a partial line */
        } else if (b == '\n' || b == '\r') {
            if (write(STDOUT_FILENO, "\n", 1) < 0) { /* best effort */ }
            done = 1;
        } else if (b == 0x7F || b == 0x08) {
            /* Backspace: DEL (0x7F) is what a terminal conventionally sends
               for the Backspace key; BS (0x08) is accepted too. */
            if (n > 0) {
                if (n >= 2 && out[n - 1] >= 0xDC00 && out[n - 1] <= 0xDFFF &&
                    out[n - 2] >= 0xD800 && out[n - 2] <= 0xDBFF) {
                    n -= 2;
                } else {
                    n -= 1;
                }
                out[n] = 0;
                if (write(STDOUT_FILENO, "\b \b", 3) < 0) { /* best effort */ }
            }
        } else if (b < 0x20) {
            /* Other control bytes (Tab, Esc, Ctrl+letter): not a character. */
        } else {
            /* Start of one UTF-8 sequence - decode it, the same bit masks
               `sc_read_hidden_line' above decodes a whole line of at once. */
            unsigned int cp = b;
            int extra;
            unsigned char cont;
            int ci;
            int bad = 0;

            if ((b & 0xE0) == 0xC0)      { cp = b & 0x1F; extra = 1; }
            else if ((b & 0xF0) == 0xE0) { cp = b & 0x0F; extra = 2; }
            else if ((b & 0xF8) == 0xF0) { cp = b & 0x07; extra = 3; }
            else if (b >= 0x80)          { extra = 0; bad = 1; }   /* stray continuation byte */
            else                          { extra = 0; }

            for (ci = 0; ci < extra && !bad; ci++) {
                got = read(STDIN_FILENO, &cont, 1);
                if (got <= 0 || (cont & 0xC0) != 0x80) {
                    bad = 1;
                } else {
                    cp = (cp << 6) | (unsigned int)(cont & 0x3F);
                }
            }

            if (!bad && n < a_capacity - 3) {
                if (cp >= 0x10000 && cp <= 0x10FFFF) {
                    unsigned int v = cp - 0x10000;
                    out[n++] = (unsigned short)(0xD800 + (v >> 10));
                    out[n++] = (unsigned short)(0xDC00 + (v & 0x3FF));
                } else {
                    out[n++] = (unsigned short)cp;
                }
                out[n] = 0;
                if (write(STDOUT_FILENO, mask_utf8, (size_t)mask_utf8_len) < 0) { /* best effort */ }
            }
        }
    }

    /* ALWAYS restore. */
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &old_t);

    if (n < 0) {
        out[0] = 0;
        return -1;
    }
    return n;
}

#endif /* _WIN32 */

#endif /* SIMPLE_CONSOLE_H */

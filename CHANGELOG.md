# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-09-03

### Added

- **`read_masked_line (a_mask: CHARACTER_32): detachable STRING_32`** and
  **`read_masked_line_default: detachable STRING_32`** (the same, with
  `a_mask` fixed at `'*'`) - read ONE line of standard input the way
  `read_hidden_line` does, except on a real console it echoes one copy of
  `a_mask` for every character accepted, so the typist can see their
  keystrokes are registering without the console ever showing what was
  typed. Added after using 1.1.0's fully-silent `read_hidden_line` in an
  installer console:

  > I was surprised by not even have dots for pw chars. That meant that I
  > didn't know whether my keystrokes were being registered. So, the dots
  > would really help.

  The feature picks its own path, the same way `read_hidden_line` does:

  - **stdin is a console** - `ENABLE_LINE_INPUT` and `ENABLE_ECHO_INPUT` are
    both cleared, and the C side becomes the line editor itself, reading one
    key event at a time with `ReadConsoleInputW` (the same primitive
    `sc_read_key` already used for a single key). Backspace removes the last
    character typed and erases its one on-screen mask (a backspace, a space,
    a backspace); Enter ends the line and prints its own newline, because
    the user's Enter is not echoed either; `ENABLE_PROCESSED_INPUT` is left
    exactly as `GetConsoleMode` found it, so Ctrl+C keeps working precisely
    the way it does for `read_hidden_line`; a surrogate pair - most emoji,
    for instance - is two UTF-16 code units but ONE accepted character: one
    mask is printed for the pair, and one Backspace erases both units and
    the mask together; every other non-character key (arrows, function
    keys, and the like) is silently ignored. The previous console mode is
    restored on **every** exit path, in C, the same restore-always
    discipline `read_hidden_line` already keeps.
  - **stdin is redirected** from a file or a pipe - this is IDENTICAL to
    `read_hidden_line`: a plain line, decoded as UTF-8, no mask printed, no
    console mode touched, so an installer's verification script that feeds
    passwords from a file keeps working unchanged.

  Both paths strip the trailing CR and/or LF; `Void` on end of input or
  failure, never a partial line; a line ended by Enter alone is the empty
  string, not `Void` - the same contract `read_hidden_line` keeps.
  `read_hidden_line` itself is unchanged, and is still the right choice
  where even the keystroke COUNT should stay unseen - a shared or recorded
  screen.

### Notes on the C layer

- `c_sc_read_masked_line` is marked **`external "C blocking inline"`**, for
  the same reason `c_sc_read_hidden_line` is: `ReadConsoleInputW` waits on
  the user, one key at a time, for as long as a password takes to type, and
  the same fleet law applies (proved in simple_winhttp 0.1.1 and
  simple_encryption 2.1.1 on 2026-09-02). The read buffer is a
  `MANAGED_POINTER` - C heap - for the same reason, and is overwritten with
  zeroes after the line is copied out, because it held a secret.
- The C layer's POSIX branch gained a parity `sc_read_masked_line` alongside
  the existing `sc_read_hidden_line` one. Same disclaimer as its sibling:
  simple_console ships and is exercised on Windows; the POSIX branch is
  written for parity and has not been run.

### Tests

37 passing before, 43 after; zero compiler warnings on a clean compile of
both targets. The six new tests cover the redirected path: the same five
shapes proven for `read_hidden_line` (ASCII, CRLF, Hebrew-and-Greek, an
empty line, and an empty file), re-run against `read_masked_line` through a
new `--masked-line-probe` mode, plus one more asserting that NEITHER a mask
character nor a Backspace-erase sequence is ever written to standard output
on the redirected path - the whole point of that path being that it is
indistinguishable from `read_hidden_line`.

**The console path is exercised headlessly**, unlike `read_hidden_line`'s:
`testing/masked_line_conpty_test.py` spawns the test executable inside a
Windows pseudoconsole (ConPTY, via `pywinpty`) - which opens no visible
window and steals no focus - types `abc`, Backspace, `d`, Enter, and asserts
the captured screen output shows the mask count go 1, 2, 3, then drop to 2
on Backspace, then rise back to 3, that the code points reported back are
97, 98, 100 (`a`, `b`, `d` - proving Backspace removed `c` and nothing
else), and that the literal string `"abcd"` never appears anywhere in the
captured output. `--masked-line-demo` on the test executable is the manual
fallback and what to look for if `pywinpty` is not available; the README
says what to look for there too.

## [1.1.0] - 2026-09-03

### Added

- **`read_hidden_line: detachable STRING_32`** - read ONE line of standard
  input without echoing it, so a password prompt cannot leave the password
  in a console log. (simple_chat's `--create-admin`, `--create-user` and
  `--reset-password` read with `io.read_line`, which echoes; a host's
  password reached a pasted console log on 2026-09-02.)

  The feature picks its own path:

  - **stdin is a console** - `ENABLE_ECHO_INPUT` is cleared for the read and
    the line comes back through `ReadConsoleW` in UTF-16, so a Hebrew or
    Greek password survives. `ENABLE_LINE_INPUT` is kept (Backspace still
    edits) and so is `ENABLE_PROCESSED_INPUT` (Ctrl+C still works). The
    previous mode is restored on **every** exit path - the restore sits in
    the C function, not behind an Eiffel rescue clause, because a console
    left echo-less stays echo-less for the session. The newline the user's
    unechoed Enter did not produce is printed for them.
  - **stdin is redirected** from a file or a pipe - the installer's
    verification scripts feed passwords this way and must keep working - the
    line is read the ordinary way and decoded as UTF-8, and no console mode
    is touched.

  Both paths strip the trailing CR and/or LF, so a CRLF file written by a
  Windows script does not leave a CR on the end of the password. `Void` on
  end of input or failure, never a partial line; a line ended by Enter alone
  is the empty string, which keeps "empty" and "nothing there" apart.

- **`is_stdin_console: BOOLEAN`** - is standard input a console rather than a
  file or a pipe? This asks about standard INPUT; the existing
  `has_real_console` asks about standard OUTPUT, and the two genuinely
  differ - a program whose output is piped to a log still reads the keyboard.

### Notes on the C layer

- `c_sc_read_hidden_line` is marked **`external "C blocking inline"`**, and
  must stay marked. `ReadConsoleW` waits for as long as the user takes to
  type a password. ISE's garbage collector stops every thread of the system
  before it collects, and a thread inside an UNMARKED external is one the
  runtime can neither see nor stop: the collection waits for the call to
  return and every other processor waits with it, at its very next
  allocation. A server that prompted on one processor would freeze the rest
  of itself until the prompt was answered. (Fleet law, proved in
  simple_winhttp 0.1.1 and simple_encryption 2.1.1 on 2026-09-02.)

  Marking is legal here only because the read buffer is a `MANAGED_POINTER` -
  C heap, which no collection moves. It is never handed the `base_address` of
  an Eiffel `SPECIAL`: the marker removes exactly the accidental protection
  such an address would be relying on. The buffer is overwritten with zeroes
  after the line is copied out of it, because it held a secret.

- `c_sc_is_stdin_console` is deliberately **not** marked: one `GetConsoleMode`
  on a handle this process already owns cannot wait on anything, and marking
  a call that short would cost two runtime transitions to save nothing.

### Tests

31 passing before, 37 after; zero compiler warnings on a clean compile of
both targets. The five new redirected-path tests re-run the test executable
itself in a probe mode (`--hidden-line-probe`) with its standard input
redirected from a file, and check the returned **code points** one by one -
ASCII, a CRLF-terminated line, a Hebrew-and-Greek password, an empty line,
and an empty file. No new dependency: the child is launched through
`EXECUTION_ENVIRONMENT.system`.

**The console path is NOT exercised by any test** and is not claimed to be.
It needs a real console, which a test runner's redirected standard input is
not. `--hidden-line-demo` on the test executable is the manual check; the
README says what to look for.

### Changed

- `package.json` version was 0.1.0 while the CHANGELOG stood at 1.0.0. Both
  now read 1.1.0.

## [Unreleased]

### Changed
- Post-session update 2025-12-08 20:52
- Post-session update 2025-12-08 20:45
- Post-session update 2025-12-08 20:16
- Inline C code into Eiffel class 
- Testing config updates, AutoTest fixes, .gitignore cleanup
- Migrate to simple_testing library
- Add GitHub Pages documentation
- Initial implementation: Console manipulation library
- first commit

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Core functionality implemented
- Test suite with comprehensive coverage
- Documentation and examples

[Unreleased]: https://github.com/simple-eiffel/simple_console/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/simple-eiffel/simple_console/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/simple-eiffel/simple_console/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/simple-eiffel/simple_console/releases/tag/v1.0.0

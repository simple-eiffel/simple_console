# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/simple-eiffel/simple_console/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/simple-eiffel/simple_console/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/simple-eiffel/simple_console/releases/tag/v1.0.0

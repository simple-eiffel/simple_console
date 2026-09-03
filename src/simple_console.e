note
	description: "[
		SCOOP-compatible console manipulation with inline C.
		Provides colored text, cursor control, and screen clearing.

		Features:
		- Win32 console API wrapper using Eric Bezault inline C pattern
		- Hidden (no-echo) line input for password prompts
		- Aggressive Design by Contract (DBC) with preconditions, postconditions, invariants
		- Optional structured logging via SIMPLE_LOGGER
		- Full error tracking and last operation status

		Usage:
			local
				console: SIMPLE_CONSOLE
			do
				create console.make
				console.set_foreground (console.Green)
				console.print_success ("Operation completed!")
			end

		With Logging:
			console.enable_logging
			console.set_log_level (console.Log_level_debug)
			-- All operations now logged
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_CONSOLE

inherit
	ANY
		redefine
			default_create
		end

create
	make, default_create

feature {NONE} -- Initialization

	make
			-- Initialize console with default state.
		do
			last_error_message := ""
			is_logging_enabled := False
		ensure
			no_error: last_error_message.is_empty
			logging_disabled: not is_logging_enabled
		end

	default_create
			-- Default initialization (alias for make).
		do
			make
		end

feature -- Colors

	set_color (a_foreground, a_background: INTEGER)
			-- Set foreground and background colors simultaneously.
			-- Colors are combined: background in high nibble, foreground in low nibble.
		require
			valid_foreground: is_valid_color (a_foreground)
			valid_background: is_valid_color (a_background)
		local
			l_color: INTEGER
		do
			l_color := a_foreground + (a_background |<< Color_nibble_shift)
			last_operation_succeeded := c_sc_set_color (l_color) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("set_color: fg=" + a_foreground.out + " bg=" + a_background.out)
			else
				last_error_message := "Failed to set console color"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

	set_foreground (a_color: INTEGER)
			-- Set foreground color only, preserving background.
		require
			valid_color: is_valid_color (a_color)
		do
			last_operation_succeeded := c_sc_set_foreground (a_color) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("set_foreground: " + color_name (a_color))
			else
				last_error_message := "Failed to set foreground color"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

	set_background (a_color: INTEGER)
			-- Set background color only, preserving foreground.
		require
			valid_color: is_valid_color (a_color)
		do
			last_operation_succeeded := c_sc_set_background (a_color) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("set_background: " + color_name (a_color))
			else
				last_error_message := "Failed to set background color"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

	reset_color
			-- Reset to default console colors (gray on black).
		do
			last_operation_succeeded := c_sc_reset_color /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("reset_color")
			else
				last_error_message := "Failed to reset console color"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

feature -- Cursor Control

	set_cursor (a_x, a_y: INTEGER)
			-- Move cursor to position (a_x, a_y). 0-based coordinates.
			-- (0,0) is top-left corner.
		require
			valid_x: a_x >= 0
			valid_y: a_y >= 0
			x_in_bounds: has_real_console implies a_x < width
			y_in_bounds: has_real_console implies a_y < height
		do
			last_operation_succeeded := c_sc_set_cursor (a_x, a_y) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("set_cursor: (" + a_x.out + ", " + a_y.out + ")")
			else
				last_error_message := "Failed to set cursor position"
				log_error (last_error_message)
			end
		ensure
			cursor_x_set: last_operation_succeeded implies cursor_x = a_x
			cursor_y_set: last_operation_succeeded implies cursor_y = a_y
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

	cursor_x: INTEGER
			-- Current cursor X position (column). 0-based.
			-- Returns -1 if console info unavailable.
		do
			Result := c_sc_get_cursor_x
		ensure
			valid_result: Result >= -1
		end

	cursor_y: INTEGER
			-- Current cursor Y position (row). 0-based.
			-- Returns -1 if console info unavailable.
		do
			Result := c_sc_get_cursor_y
		ensure
			valid_result: Result >= -1
		end

	show_cursor
			-- Make cursor visible.
		do
			last_operation_succeeded := c_sc_show_cursor (1) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("show_cursor")
			else
				last_error_message := "Failed to show cursor"
				log_error (last_error_message)
			end
		ensure
			cursor_visible: last_operation_succeeded implies is_cursor_visible
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

	hide_cursor
			-- Make cursor invisible.
		do
			last_operation_succeeded := c_sc_show_cursor (0) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("hide_cursor")
			else
				last_error_message := "Failed to hide cursor"
				log_error (last_error_message)
			end
		ensure
			cursor_hidden: last_operation_succeeded implies not is_cursor_visible
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

	is_cursor_visible: BOOLEAN
			-- Is the cursor currently visible?
		do
			Result := c_sc_is_cursor_visible /= 0
		end

feature -- Screen Information

	width: INTEGER
			-- Console window width in characters.
			-- Returns 80 as default if console info unavailable.
		do
			Result := c_sc_get_width
		ensure
			positive: Result > 0
		end

	height: INTEGER
			-- Console window height in characters.
			-- Returns 25 as default if console info unavailable.
		do
			Result := c_sc_get_height
		ensure
			positive: Result > 0
		end

feature -- Screen Operations

	clear
			-- Clear the entire screen and reset cursor to (0,0).
		do
			last_operation_succeeded := c_sc_clear /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("clear")
			else
				last_error_message := "Failed to clear screen"
				log_error (last_error_message)
			end
		ensure
			cursor_at_home: last_operation_succeeded implies (cursor_x = 0 and cursor_y = 0)
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

	clear_line
			-- Clear from cursor to end of current line.
		do
			last_operation_succeeded := c_sc_clear_line /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("clear_line")
			else
				last_error_message := "Failed to clear line"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Set console window title.
		require
			title_not_void: a_title /= Void
			title_not_empty: not a_title.is_empty
		local
			l_title: C_STRING
		do
			create l_title.make (a_title.to_string_8)
			last_operation_succeeded := c_sc_set_title (l_title.item) /= 0
			if last_operation_succeeded then
				last_error_message := ""
				log_debug ("set_title: " + a_title.to_string_8)
			else
				last_error_message := "Failed to set window title"
				log_error (last_error_message)
			end
		ensure
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
		end

feature -- Convenience: Print with Color

	print_colored (a_text: READABLE_STRING_GENERAL; a_color: INTEGER)
			-- Print a_text in a_color, then reset.
		require
			text_not_void: a_text /= Void
			valid_color: is_valid_color (a_color)
		do
			set_foreground (a_color)
			print (a_text)
			reset_color
		end

	print_at (a_text: READABLE_STRING_GENERAL; a_x, a_y: INTEGER)
			-- Print a_text at position (a_x, a_y).
		require
			text_not_void: a_text /= Void
			valid_x: a_x >= 0
			valid_y: a_y >= 0
		do
			set_cursor (a_x, a_y)
			print (a_text)
		end

feature -- CLI Output Helpers

	print_line (a_text: READABLE_STRING_GENERAL)
			-- Print a_text followed by newline.
		require
			text_not_void: a_text /= Void
		do
			print (a_text)
			print ("%N")
		end

	print_success (a_text: READABLE_STRING_GENERAL)
			-- Print success message in green.
		require
			text_not_void: a_text /= Void
		do
			set_foreground (Green)
			print (a_text)
			reset_color
			print ("%N")
		end

	print_error (a_text: READABLE_STRING_GENERAL)
			-- Print error message in red.
		require
			text_not_void: a_text /= Void
		do
			set_foreground (Red)
			print (a_text)
			reset_color
			print ("%N")
		end

	print_warning (a_text: READABLE_STRING_GENERAL)
			-- Print warning message in yellow.
		require
			text_not_void: a_text /= Void
		do
			set_foreground (Yellow)
			print (a_text)
			reset_color
			print ("%N")
		end

	print_info (a_text: READABLE_STRING_GENERAL)
			-- Print info message in cyan.
		require
			text_not_void: a_text /= Void
		do
			set_foreground (Cyan)
			print (a_text)
			reset_color
			print ("%N")
		end

feature -- Input

	is_stdin_console: BOOLEAN
			-- Is standard input a real console, rather than a file or a pipe
			-- redirected into this process?
			-- `read_hidden_line' suppresses echo only when this is True.
			-- Note this asks about standard INPUT; `has_real_console' asks
			-- about standard output, and the two can differ - a program whose
			-- output is piped to a log still reads from the keyboard.
		do
			Result := c_sc_is_stdin_console /= 0
		end

	read_hidden_line: detachable STRING_32
			-- One line of standard input, read WITHOUT echoing what the user
			-- types when `is_stdin_console' - and read as an ordinary line,
			-- console modes untouched, when standard input is redirected from
			-- a file or a pipe, which is how an installer's verification
			-- script feeds a password in.
			--
			-- Void on end of input or on failure, NEVER a partial line. A line
			-- the user ended by pressing Enter alone is the empty string, not
			-- Void. The trailing CR and/or LF is stripped on both paths.
			--
			-- Written for password prompts. A `--create-admin' that reads with
			-- `io.read_line' leaves the host's password in the console log,
			-- which is exactly how one was published on 2026-09-02.
			--
			-- Prefer this over `read_masked_line' when the typist should get NO
			-- feedback at all - a shared or recorded screen, where even the
			-- keystroke COUNT should stay unseen. `read_masked_line' is the
			-- better choice for an ordinary password prompt: it echoes a mask
			-- character per keystroke, so the typist can see their input is
			-- registering.
		do
			if is_stdin_console then
				Result := hidden_line_from_console
			else
				Result := plain_line_from_redirected_input
			end
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

	read_masked_line (a_mask: CHARACTER_32): detachable STRING_32
			-- One line of standard input, echoed with `a_mask' - one copy per
			-- character accepted - so the typist can see their keystrokes are
			-- registering, without the console ever showing what was typed.
			-- Takes the same two paths as `read_hidden_line', chosen the same
			-- way:
			--
			-- Standard input is a console. `ENABLE_LINE_INPUT' and
			-- `ENABLE_ECHO_INPUT' are cleared for the read, and this feature's C
			-- half becomes the line editor: Backspace removes the last
			-- character typed and erases its one on-screen mask; Enter ends the
			-- line and prints a newline of its own, because the user's Enter was
			-- not echoed either; Ctrl+C keeps working, exactly as it does for
			-- `read_hidden_line'; a surrogate pair (most emoji, for instance) is
			-- accepted, masked, and erased as the ONE character it represents,
			-- never as two; every other non-character key - the arrows, the
			-- function keys, and the like - is silently ignored. The previous
			-- console mode is restored on every exit path, in C, the same way
			-- `read_hidden_line' restores its own.
			--
			-- Standard input is redirected from a file or a pipe. This is
			-- IDENTICAL to `read_hidden_line': a plain line, decoded as UTF-8,
			-- no mask printed, no console mode touched. An installer's
			-- verification script feeds passwords this way and must keep
			-- working.
			--
			-- Void on end of input or on failure, NEVER a partial line - the
			-- same contract `read_hidden_line' keeps. A line the user ended by
			-- pressing Enter alone is the empty string, not Void.
			--
			-- Prefer this over `read_hidden_line' for an ordinary password
			-- prompt. Larry, after using 1.1.0's fully-silent `read_hidden_line'
			-- in an installer console: "I was surprised by not even have dots
			-- for pw chars. That meant that I didn't know whether my keystrokes
			-- were being registered. So, the dots would really help."
		do
			if is_stdin_console then
				Result := masked_line_from_console (a_mask)
			else
				Result := plain_line_from_redirected_input
			end
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

	read_masked_line_default: detachable STRING_32
			-- `read_masked_line' with `a_mask' set to `'*'' - the ordinary case,
			-- and the one the two-argument form exists to let a caller override.
			-- See `read_masked_line'.
		do
			Result := read_masked_line ('*')
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
			error_cleared_on_success: last_operation_succeeded implies last_error_message.is_empty
			error_set_on_failure: not last_operation_succeeded implies not last_error_message.is_empty
		end

feature -- Status

	last_operation_succeeded: BOOLEAN
			-- Did the last operation succeed?

	last_error_message: STRING
			-- Human-readable error message from last failed operation.
			-- Empty if last operation succeeded.

	has_real_console: BOOLEAN
			-- Do we have a real Windows console (not mintty/pipe)?
			-- Console operations only work properly when this is True.
		do
			Result := c_sc_has_real_console /= 0
		end

feature -- Logging Configuration

	is_logging_enabled: BOOLEAN
			-- Is operation logging enabled?

	logger: detachable SIMPLE_LOGGER
			-- Logger instance (created lazily when logging enabled).

	log_level: INTEGER
			-- Current log level (default: info).

	enable_logging
			-- Enable logging of console operations.
		do
			if not attached logger then
				create logger.make
			end
			is_logging_enabled := True
			log_info ("Console logging enabled")
		ensure
			logging_enabled: is_logging_enabled
			logger_exists: attached logger
		end

	disable_logging
			-- Disable logging of console operations.
		do
			log_info ("Console logging disabled")
			is_logging_enabled := False
		ensure
			logging_disabled: not is_logging_enabled
		end

	set_log_level (a_level: INTEGER)
			-- Set minimum log level for console operations.
		require
			valid_level: a_level >= Log_level_debug and a_level <= Log_level_fatal
		do
			log_level := a_level
			if attached logger as l then
				l.set_level (a_level)
			end
		ensure
			level_set: log_level = a_level
		end

feature -- Log Level Constants

	Log_level_debug: INTEGER = 1
	Log_level_info: INTEGER = 2
	Log_level_warn: INTEGER = 3
	Log_level_error: INTEGER = 4
	Log_level_fatal: INTEGER = 5

feature -- Color Validation

	is_valid_color (a_color: INTEGER): BOOLEAN
			-- Is a_color a valid console color (0-15)?
		do
			Result := a_color >= Black and a_color <= White
		ensure
			definition: Result = (a_color >= Black and a_color <= White)
		end

	color_name (a_color: INTEGER): STRING
			-- Human-readable name for color.
		require
			valid_color: is_valid_color (a_color)
		do
			inspect a_color
			when 0 then Result := "Black"
			when 1 then Result := "Dark_blue"
			when 2 then Result := "Dark_green"
			when 3 then Result := "Dark_cyan"
			when 4 then Result := "Dark_red"
			when 5 then Result := "Dark_magenta"
			when 6 then Result := "Dark_yellow"
			when 7 then Result := "Gray"
			when 8 then Result := "Dark_gray"
			when 9 then Result := "Blue"
			when 10 then Result := "Green"
			when 11 then Result := "Cyan"
			when 12 then Result := "Red"
			when 13 then Result := "Magenta"
			when 14 then Result := "Yellow"
			when 15 then Result := "White"
			else
				Result := "Unknown"
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Color Constants

	Black: INTEGER = 0
	Dark_blue: INTEGER = 1
	Dark_green: INTEGER = 2
	Dark_cyan: INTEGER = 3
	Dark_red: INTEGER = 4
	Dark_magenta: INTEGER = 5
	Dark_yellow: INTEGER = 6
	Gray: INTEGER = 7
	Dark_gray: INTEGER = 8
	Blue: INTEGER = 9
	Green: INTEGER = 10
	Cyan: INTEGER = 11
	Red: INTEGER = 12
	Magenta: INTEGER = 13
	Yellow: INTEGER = 14
	White: INTEGER = 15

feature {NONE} -- Input Implementation

	hidden_line_from_console: detachable STRING_32
			-- One line read from the console with `ENABLE_ECHO_INPUT' cleared
			-- for the duration of the read and restored immediately after it.
		require
			stdin_is_console: is_stdin_console
		local
			l_buffer: MANAGED_POINTER
			l_count, i: INTEGER
		do
				-- The buffer is C heap on purpose. `c_sc_read_hidden_line' is
				-- marked `blocking' because it waits on the user, which lets a
				-- garbage collection run - and move Eiffel objects - while C
				-- still holds this address. A `SPECIAL''s `base_address' would
				-- become a dangling pointer the moment the collector moved it;
				-- a MANAGED_POINTER's memory does not move. (The rule this
				-- follows: simple_encryption CHANGELOG 2.1.1 - an external that
				-- hands C the address of an Eiffel area must NOT be marked, and
				-- an external that is marked must hand C nothing but C heap.)
			create l_buffer.make (Hidden_line_capacity * Utf_16_unit_bytes)
			l_count := c_sc_read_hidden_line (l_buffer.item, Hidden_line_capacity)
			if l_count >= 0 then
				Result := {UTF_CONVERTER}.utf_16_0_subpointer_to_string_32 (l_buffer, 0, l_count - 1, False)
				last_operation_succeeded := True
				last_error_message := ""
				log_debug ("read_hidden_line: console path, " + l_count.out + " code units")
			else
				last_operation_succeeded := False
				last_error_message := "Failed to read a hidden line from the console"
				log_error (last_error_message)
			end
				-- The buffer held a secret. Overwrite it before letting go.
			from
				i := 0
			until
				i >= Hidden_line_capacity
			loop
				l_buffer.put_natural_16 (0, i * Utf_16_unit_bytes)
				i := i + 1
			end
				-- The user's Enter was not echoed either, so end the line here.
			io.put_new_line
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
		end

	masked_line_from_console (a_mask: CHARACTER_32): detachable STRING_32
			-- One line read from the console with `ENABLE_LINE_INPUT' and
			-- `ENABLE_ECHO_INPUT' both cleared for the duration of the read and
			-- restored immediately after it. `sc_read_masked_line' is the line
			-- editor here - Backspace, Enter, the mask itself - because Windows
			-- has no console mode that echoes a substitute character; see
			-- `simple_console.h' for why that whole job has to live in C.
		require
			stdin_is_console: is_stdin_console
		local
			l_buffer: MANAGED_POINTER
			l_count, i: INTEGER
		do
				-- The buffer is C heap on purpose, for the same reason as
				-- `hidden_line_from_console': `c_sc_read_masked_line' is marked
				-- `blocking' because it waits on the user, which lets a garbage
				-- collection run - and move Eiffel objects - while C still holds
				-- this address. Only a MANAGED_POINTER's memory does not move.
			create l_buffer.make (Hidden_line_capacity * Utf_16_unit_bytes)
			l_count := c_sc_read_masked_line (l_buffer.item, Hidden_line_capacity, a_mask.natural_32_code)
			if l_count >= 0 then
				Result := {UTF_CONVERTER}.utf_16_0_subpointer_to_string_32 (l_buffer, 0, l_count - 1, False)
				last_operation_succeeded := True
				last_error_message := ""
				log_debug ("read_masked_line: console path, " + l_count.out + " code units")
			else
				last_operation_succeeded := False
				last_error_message := "Failed to read a masked line from the console"
				log_error (last_error_message)
			end
				-- The buffer held a secret. Overwrite it before letting go.
			from
				i := 0
			until
				i >= Hidden_line_capacity
			loop
				l_buffer.put_natural_16 (0, i * Utf_16_unit_bytes)
				i := i + 1
			end
				-- Unlike `hidden_line_from_console', the newline is NOT printed
				-- here: the C side already wrote it the moment it saw Enter,
				-- alongside the mask characters it was already printing.
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
		end

	plain_line_from_redirected_input: detachable STRING_32
			-- One line read the ordinary way from redirected standard input and
			-- decoded as UTF-8. No console mode is touched on this path, and
			-- nothing is hidden - stdin is a file or a pipe, so there is no
			-- terminal to hide it from.
		local
			l_line: STRING_8
		do
			if io.input.file_readable then
				io.input.read_line
				l_line := io.input.last_string.twin
					-- A CRLF file fed in on Windows can leave the CR behind.
				from
				until
					l_line.is_empty or else
						(l_line.item (l_line.count) /= '%R' and l_line.item (l_line.count) /= '%N')
				loop
					l_line.remove_tail (1)
				end
				if l_line.is_empty and then io.input.end_of_file then
						-- Nothing was there to read: end of input, not a line.
					last_operation_succeeded := False
					last_error_message := "End of input: no line to read"
					log_error (last_error_message)
				else
					Result := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_line)
					last_operation_succeeded := True
					last_error_message := ""
					log_debug ("read_hidden_line: redirected path, " + l_line.count.out + " bytes")
				end
			else
				last_operation_succeeded := False
				last_error_message := "Standard input is not readable"
				log_error (last_error_message)
			end
		ensure
			line_exactly_when_succeeded: (Result /= Void) = last_operation_succeeded
		end

feature {NONE} -- Logging Implementation

	log_debug (a_message: STRING)
			-- Log debug message if logging enabled.
		require
			message_not_void: a_message /= Void
		do
			if is_logging_enabled and then attached logger as l then
				l.debug_log (a_message)
			end
		end

	log_info (a_message: STRING)
			-- Log info message if logging enabled.
		require
			message_not_void: a_message /= Void
		do
			if is_logging_enabled and then attached logger as l then
				l.info (a_message)
			end
		end

	log_error (a_message: STRING)
			-- Log error message if logging enabled.
		require
			message_not_void: a_message /= Void
		do
			if is_logging_enabled and then attached logger as l then
				l.error (a_message)
			end
		end

feature {NONE} -- C externals (using simple_console.h)

	c_sc_set_color (a_color: INTEGER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_set_color($a_color);"
		end

	c_sc_set_foreground (a_color: INTEGER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_set_foreground($a_color);"
		end

	c_sc_set_background (a_color: INTEGER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_set_background($a_color);"
		end

	c_sc_reset_color: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_reset_color();"
		end

	c_sc_set_cursor (a_x, a_y: INTEGER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_set_cursor($a_x, $a_y);"
		end

	c_sc_get_cursor_x: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_get_cursor_x();"
		end

	c_sc_get_cursor_y: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_get_cursor_y();"
		end

	c_sc_get_width: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_get_width();"
		end

	c_sc_get_height: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_get_height();"
		end

	c_sc_clear: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_clear();"
		end

	c_sc_clear_line: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_clear_line();"
		end

	c_sc_set_title (a_title: POINTER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_set_title((const char*)$a_title);"
		end

	c_sc_show_cursor (a_visible: INTEGER): INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_show_cursor($a_visible);"
		end

	c_sc_is_cursor_visible: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_is_cursor_visible();"
		end

	c_sc_has_real_console: INTEGER
		external "C inline use %"simple_console.h%""
		alias "return sc_has_real_console();"
		end

	c_sc_is_stdin_console: INTEGER
			-- Deliberately NOT `blocking': one `GetConsoleMode' on a handle this
			-- process already owns, measured in microseconds. It cannot wait on
			-- anything, and marking a call this short would cost two runtime
			-- transitions to save nothing.
		external "C inline use %"simple_console.h%""
		alias "return sc_is_stdin_console();"
		end

	c_sc_read_hidden_line (a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- MARKED `blocking', and it must stay marked. `ReadConsoleW' WAITS -
			-- for as long as the user takes to type a password and press Enter,
			-- which may be minutes. ISE's garbage collector stops every thread of
			-- the system before it collects, and a thread inside an UNMARKED
			-- external is one the runtime can neither see nor stop: the collection
			-- waits for that call to return, and every other processor waits with
			-- it, at its very next allocation. A server that prompted for a
			-- password on one processor would freeze the rest of itself until the
			-- prompt was answered. The marker tells the runtime this thread has
			-- left Eiffel, so a collection may proceed without it. (Fleet law,
			-- proved in simple_winhttp 0.1.1 and simple_encryption 2.1.1 on
			-- 2026-09-02: a C external that waits must be marked `C blocking'.)
			--
			-- Marking is SAFE here only because `a_buffer' is a MANAGED_POINTER -
			-- C heap, which no collection moves. It must never be handed the
			-- `base_address' of an Eiffel SPECIAL: the marker removes exactly the
			-- accidental protection such an address relies on.
		external "C blocking inline use %"simple_console.h%""
		alias "return sc_read_hidden_line((void *)$a_buffer, (int)$a_capacity);"
		end

	c_sc_read_masked_line (a_buffer: POINTER; a_capacity: INTEGER; a_mask_cp: NATURAL_32): INTEGER
			-- MARKED `blocking', for the same reason as `c_sc_read_hidden_line':
			-- `ReadConsoleInputW' WAITS on the user, one key at a time, for as
			-- long as a password takes to type. The same fleet law applies (proved
			-- in simple_winhttp 0.1.1 and simple_encryption 2.1.1 on 2026-09-02):
			-- a C external that waits must be marked `C blocking', and marking is
			-- SAFE here only because `a_buffer' is a MANAGED_POINTER - C heap,
			-- which no collection moves, and never the `base_address' of an
			-- Eiffel SPECIAL.
		external "C blocking inline use %"simple_console.h%""
		alias "return sc_read_masked_line((void *)$a_buffer, (int)$a_capacity, (unsigned int)$a_mask_cp);"
		end

feature {NONE} -- Constants

	Hidden_line_capacity: INTEGER = 1024
			-- Room, in UTF-16 code units, for one hidden line including its
			-- terminating null. The console read truncates beyond it.

	Utf_16_unit_bytes: INTEGER = 2
			-- Bytes in one UTF-16 code unit.

	Color_nibble_shift: INTEGER = 4
			-- Bit shift to place background color in high nibble

	Max_color_value: INTEGER = 15
			-- Maximum valid color value (equals White)

invariant
	error_message_not_void: last_error_message /= Void
	color_constants_valid: Black = 0 and White = Max_color_value
	log_level_valid: log_level >= 0 and log_level <= Log_level_fatal

end

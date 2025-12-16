note
	description: "[
		SCOOP-compatible console manipulation with inline C.
		Provides colored text, cursor control, and screen clearing.

		Features:
		- Win32 console API wrapper using Eric Bezault inline C pattern
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
			l_color := a_foreground + (a_background |<< 4)
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
			Result := a_color >= 0 and a_color <= 15
		ensure
			definition: Result = (a_color >= 0 and a_color <= 15)
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

invariant
	error_message_not_void: last_error_message /= Void
	color_constants_valid: Black = 0 and White = 15
	log_level_valid: log_level >= 0 and log_level <= Log_level_fatal

end

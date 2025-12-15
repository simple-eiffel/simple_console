note
	description: "[
		SCOOP-compatible console manipulation with inline C.
		Provides colored text, cursor control, and screen clearing.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_CONSOLE

create
	make, default_create

feature {NONE} -- Initialization

	make
			-- Initialize console.
		do
			-- Default initialization (nothing special needed)
		end

feature -- Colors

	set_color (a_foreground, a_background: INTEGER)
			-- Set foreground and background colors.
		require
			valid_foreground: a_foreground >= 0 and a_foreground <= 15
			valid_background: a_background >= 0 and a_background <= 15
		local
			l_color: INTEGER
		do
			l_color := a_foreground + (a_background |<< 4)
			last_operation_succeeded := c_sc_set_color (l_color) /= 0
		end

	set_foreground (a_color: INTEGER)
			-- Set foreground color only.
		require
			valid_color: a_color >= 0 and a_color <= 15
		do
			last_operation_succeeded := c_sc_set_foreground (a_color) /= 0
		end

	set_background (a_color: INTEGER)
			-- Set background color only.
		require
			valid_color: a_color >= 0 and a_color <= 15
		do
			last_operation_succeeded := c_sc_set_background (a_color) /= 0
		end

	reset_color
			-- Reset to default console colors.
		do
			last_operation_succeeded := c_sc_reset_color /= 0
		end

feature -- Cursor Control

	set_cursor (a_x, a_y: INTEGER)
			-- Move cursor to position (a_x, a_y). 0-based.
		require
			valid_x: a_x >= 0
			valid_y: a_y >= 0
		do
			last_operation_succeeded := c_sc_set_cursor (a_x, a_y) /= 0
		end

	cursor_x: INTEGER
			-- Current cursor X position.
		do
			Result := c_sc_get_cursor_x
		end

	cursor_y: INTEGER
			-- Current cursor Y position.
		do
			Result := c_sc_get_cursor_y
		end

	show_cursor
			-- Make cursor visible.
		do
			last_operation_succeeded := c_sc_show_cursor (1) /= 0
		end

	hide_cursor
			-- Make cursor invisible.
		do
			last_operation_succeeded := c_sc_show_cursor (0) /= 0
		end

	is_cursor_visible: BOOLEAN
			-- Is the cursor currently visible?
		do
			Result := c_sc_is_cursor_visible /= 0
		end

feature -- Screen Information

	width: INTEGER
			-- Console window width in characters.
		do
			Result := c_sc_get_width
		end

	height: INTEGER
			-- Console window height in characters.
		do
			Result := c_sc_get_height
		end

feature -- Screen Operations

	clear
			-- Clear the entire screen.
		do
			last_operation_succeeded := c_sc_clear /= 0
		end

	clear_line
			-- Clear from cursor to end of current line.
		do
			last_operation_succeeded := c_sc_clear_line /= 0
		end

	set_title (a_title: READABLE_STRING_GENERAL)
			-- Set console window title.
		require
			title_not_void: a_title /= Void
		local
			l_title: C_STRING
		do
			create l_title.make (a_title.to_string_8)
			last_operation_succeeded := c_sc_set_title (l_title.item) /= 0
		end

feature -- Convenience: Print with Color

	print_colored (a_text: READABLE_STRING_GENERAL; a_color: INTEGER)
			-- Print a_text in a_color, then reset.
		require
			text_not_void: a_text /= Void
			valid_color: a_color >= 0 and a_color <= 15
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

	has_real_console: BOOLEAN
			-- Do we have a real Windows console (not mintty/pipe)?
			-- Console operations only work properly when this is True.
		do
			Result := c_sc_has_real_console /= 0
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

end

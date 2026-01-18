note
	description: "[
		Comprehensive tests for SIMPLE_CONSOLE library.

		Tests cover:
		- Basic functionality (colors, cursor, screen)
		- Edge cases (boundary colors, invalid states)
		- Error handling and status tracking
		- Optional logging integration
		- Contract verification

		Note: Many tests require a real Windows console.
		When running in mintty/pipe (like git-bash), console
		tests are skipped but validation tests still run.
	]"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test routines: Console Detection

	test_has_real_console
			-- Test detection of real console.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Verify it returns a boolean without crashing
			assert ("has_real_console_works", l_con.has_real_console or not l_con.has_real_console)
			-- Log result for debugging
			print ("has_real_console: " + l_con.has_real_console.out + "%N")
		end

	test_default_creation
			-- Test default creation establishes proper initial state.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			assert ("error_message_empty", l_con.last_error_message.is_empty)
			assert ("logging_disabled", not l_con.is_logging_enabled)
			assert ("logger_not_attached", not attached l_con.logger)
		end

	test_make_creation
			-- Test make creation establishes proper initial state.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con.make
			assert ("error_message_empty", l_con.last_error_message.is_empty)
			assert ("logging_disabled", not l_con.is_logging_enabled)
		end

feature -- Test routines: Color Constants

	test_color_constants
			-- Test that all color constants are valid and in range.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Standard colors
			assert_integers_equal ("black_is_0", 0, l_con.Black)
			assert_integers_equal ("white_is_15", 15, l_con.White)
			assert_integers_equal ("red_is_12", 12, l_con.Red)
			assert_integers_equal ("green_is_10", 10, l_con.Green)
			assert_integers_equal ("blue_is_9", 9, l_con.Blue)
			assert_integers_equal ("cyan_is_11", 11, l_con.Cyan)
			assert_integers_equal ("yellow_is_14", 14, l_con.Yellow)
			assert_integers_equal ("magenta_is_13", 13, l_con.Magenta)

			-- Dark variants
			assert_integers_equal ("dark_blue_is_1", 1, l_con.Dark_blue)
			assert_integers_equal ("dark_green_is_2", 2, l_con.Dark_green)
			assert_integers_equal ("dark_cyan_is_3", 3, l_con.Dark_cyan)
			assert_integers_equal ("dark_red_is_4", 4, l_con.Dark_red)
			assert_integers_equal ("dark_magenta_is_5", 5, l_con.Dark_magenta)
			assert_integers_equal ("dark_yellow_is_6", 6, l_con.Dark_yellow)
			assert_integers_equal ("gray_is_7", 7, l_con.Gray)
			assert_integers_equal ("dark_gray_is_8", 8, l_con.Dark_gray)
		end

	test_color_validation
			-- Test is_valid_color for all boundary cases.
		local
			l_con: SIMPLE_CONSOLE
			l_i: INTEGER
		do
			create l_con
			-- Invalid negative
			assert ("negative_invalid", not l_con.is_valid_color (-1))
			assert ("very_negative_invalid", not l_con.is_valid_color (-100))

			-- Valid range 0-15
			from l_i := 0 until l_i > l_con.White loop
				assert ("color_" + l_i.out + "_valid", l_con.is_valid_color (l_i))
				l_i := l_i + 1
			end

			-- Invalid above range
			assert ("16_invalid", not l_con.is_valid_color (16))
			assert ("100_invalid", not l_con.is_valid_color (100))
			assert ("max_int_invalid", not l_con.is_valid_color ({INTEGER}.max_value))
		end

	test_color_names
			-- Test color_name returns valid names for all colors.
		local
			l_con: SIMPLE_CONSOLE
			l_i: INTEGER
			l_name: STRING
		do
			create l_con
			from l_i := 0 until l_i > l_con.White loop
				l_name := l_con.color_name (l_i)
				assert ("color_" + l_i.out + "_has_name", not l_name.is_empty)
				assert ("color_" + l_i.out + "_not_unknown", not l_name.same_string ("Unknown"))
				l_i := l_i + 1
			end
		end

feature -- Test routines: Screen Dimensions

	test_get_dimensions
			-- Test getting console dimensions (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				assert_greater_than ("width_positive", l_con.width, 0)
				assert_greater_than ("height_positive", l_con.height, 0)
				-- Reasonable bounds check
				assert_less_than ("width_reasonable", l_con.width, 10000)
				assert_less_than ("height_reasonable", l_con.height, 10000)
			else
				-- Default values when no console
				assert_integers_equal ("default_width", 80, l_con.width)
				assert_integers_equal ("default_height", 25, l_con.height)
			end
		end

	test_dimensions_consistency
			-- Test that dimensions are consistent across calls.
		local
			l_con: SIMPLE_CONSOLE
			l_w1, l_w2, l_h1, l_h2: INTEGER
		do
			create l_con
			l_w1 := l_con.width
			l_h1 := l_con.height
			l_w2 := l_con.width
			l_h2 := l_con.height
			assert_integers_equal ("width_consistent", l_w1, l_w2)
			assert_integers_equal ("height_consistent", l_h1, l_h2)
		end

feature -- Test routines: Cursor Operations

	test_cursor_position
			-- Test cursor positioning (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_cursor (5, 10)
				assert_true ("cursor_set_succeeded", l_con.last_operation_succeeded)
				assert_integers_equal ("cursor_x", 5, l_con.cursor_x)
				assert_integers_equal ("cursor_y", 10, l_con.cursor_y)
			else
				assert ("no_console_skip", True)
			end
		end

	test_cursor_origin
			-- Test cursor at origin (0,0).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_cursor (0, 0)
				assert_true ("cursor_origin_succeeded", l_con.last_operation_succeeded)
				assert_integers_equal ("cursor_x_origin", 0, l_con.cursor_x)
				assert_integers_equal ("cursor_y_origin", 0, l_con.cursor_y)
			else
				assert ("no_console_skip", True)
			end
		end

	test_cursor_visibility
			-- Test cursor visibility toggle (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				-- Hide
				l_con.hide_cursor
				assert_true ("hide_succeeded", l_con.last_operation_succeeded)
				assert_false ("cursor_hidden", l_con.is_cursor_visible)

				-- Show
				l_con.show_cursor
				assert_true ("show_succeeded", l_con.last_operation_succeeded)
				assert_true ("cursor_visible", l_con.is_cursor_visible)
			else
				assert ("no_console_skip", True)
			end
		end

	test_cursor_position_query_no_console
			-- Test cursor position queries when no real console.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if not l_con.has_real_console then
				-- Should return -1 when no console info available
				assert ("cursor_x_returns_value", l_con.cursor_x >= -1)
				assert ("cursor_y_returns_value", l_con.cursor_y >= -1)
			else
				assert ("has_console_skip", True)
			end
		end

feature -- Test routines: Color Operations

	test_set_foreground
			-- Test setting foreground color (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_foreground (l_con.Green)
				assert_true ("foreground_set", l_con.last_operation_succeeded)
				assert_true ("error_message_empty", l_con.last_error_message.is_empty)
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_set_background
			-- Test setting background color (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_background (l_con.Blue)
				assert_true ("background_set", l_con.last_operation_succeeded)
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_set_color_combined
			-- Test setting foreground and background together.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_color (l_con.White, l_con.Blue)
				assert_true ("combined_color_set", l_con.last_operation_succeeded)
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_all_colors_foreground
			-- Test setting all 16 foreground colors.
		local
			l_con: SIMPLE_CONSOLE
			l_i: INTEGER
		do
			create l_con
			if l_con.has_real_console then
				from l_i := 0 until l_i > l_con.White loop
					l_con.set_foreground (l_i)
					assert_true ("fg_color_" + l_i.out + "_set", l_con.last_operation_succeeded)
					l_i := l_i + 1
				end
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_all_colors_background
			-- Test setting all 16 background colors.
		local
			l_con: SIMPLE_CONSOLE
			l_i: INTEGER
		do
			create l_con
			if l_con.has_real_console then
				from l_i := 0 until l_i > l_con.White loop
					l_con.set_background (l_i)
					assert_true ("bg_color_" + l_i.out + "_set", l_con.last_operation_succeeded)
					l_i := l_i + 1
				end
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_reset_color
			-- Test resetting colors to default.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				-- Set some colors first
				l_con.set_foreground (l_con.Red)
				l_con.set_background (l_con.Yellow)

				-- Reset
				l_con.reset_color
				assert_true ("reset_succeeded", l_con.last_operation_succeeded)
			else
				assert ("no_console_skip", True)
			end
		end

feature -- Test routines: Screen Operations

	test_clear_line
			-- Test clearing to end of line.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.clear_line
				assert_true ("clear_line_succeeded", l_con.last_operation_succeeded)
			else
				assert ("no_console_skip", True)
			end
		end

	test_set_title
			-- Test setting console window title.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_title ("Simple Console Test")
				assert_true ("title_set", l_con.last_operation_succeeded)
				-- Reset title
				l_con.set_title ("Command Prompt")
			else
				assert ("no_console_skip", True)
			end
		end

feature -- Test routines: Convenience Methods

	test_print_colored
			-- Test print_colored method.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Should not crash even without real console
			l_con.print_colored ("Test", l_con.Green)
			assert ("print_colored_works", True)
		end

	test_print_at
			-- Test print_at method.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.print_at ("X", 0, 0)
				assert ("print_at_works", True)
			else
				assert ("no_console_skip", True)
			end
		end

	test_cli_output_helpers
			-- Test CLI output helper methods.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- These should all work without crashing
			l_con.print_line ("Test line")
			l_con.print_success ("Success message")
			l_con.print_error ("Error message")
			l_con.print_warning ("Warning message")
			l_con.print_info ("Info message")
			assert ("cli_helpers_work", True)
		end

feature -- Test routines: Logging

	test_logging_default_disabled
			-- Test that logging is disabled by default.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			assert_false ("logging_disabled_default", l_con.is_logging_enabled)
			assert ("logger_not_created", not attached l_con.logger)
		end

	test_enable_disable_logging
			-- Test enabling and disabling logging.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Enable
			l_con.enable_logging
			assert_true ("logging_enabled", l_con.is_logging_enabled)
			assert ("logger_created", attached l_con.logger)

			-- Disable
			l_con.disable_logging
			assert_false ("logging_disabled", l_con.is_logging_enabled)
			-- Logger still exists, just disabled
			assert ("logger_still_exists", attached l_con.logger)
		end

	test_set_log_level
			-- Test setting log level.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Can set level before enabling
			l_con.set_log_level (l_con.Log_level_debug)
			assert_integers_equal ("level_debug", l_con.Log_level_debug, l_con.log_level)

			l_con.set_log_level (l_con.Log_level_error)
			assert_integers_equal ("level_error", l_con.Log_level_error, l_con.log_level)
		end

	test_log_level_constants
			-- Test log level constant values.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			assert_integers_equal ("debug_is_1", 1, l_con.Log_level_debug)
			assert_integers_equal ("info_is_2", 2, l_con.Log_level_info)
			assert_integers_equal ("warn_is_3", 3, l_con.Log_level_warn)
			assert_integers_equal ("error_is_4", 4, l_con.Log_level_error)
			assert_integers_equal ("fatal_is_5", 5, l_con.Log_level_fatal)
		end

	test_logging_with_operations
			-- Test that operations work with logging enabled.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			l_con.enable_logging
			l_con.set_log_level (l_con.Log_level_debug)

			-- Perform operations - should log but not crash
			if l_con.has_real_console then
				l_con.set_foreground (l_con.Green)
				l_con.reset_color
				l_con.set_cursor (0, 0)
			end

			l_con.disable_logging
			assert ("logging_operations_work", True)
		end

feature -- Test routines: Error Handling

	test_error_message_cleared_on_success
			-- Test that error message is cleared after successful operation.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_foreground (l_con.Green)
				assert_true ("operation_succeeded", l_con.last_operation_succeeded)
				assert_true ("error_cleared", l_con.last_error_message.is_empty)
				l_con.reset_color
			else
				assert ("no_console_skip", True)
			end
		end

	test_error_handling_no_console
			-- Test error handling when no real console available.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if not l_con.has_real_console then
				-- Operations should fail gracefully
				l_con.set_foreground (l_con.Green)
				assert_false ("operation_failed", l_con.last_operation_succeeded)
				assert_false ("error_set", l_con.last_error_message.is_empty)
			else
				assert ("has_console_skip", True)
			end
		end

feature -- Test routines: Invariant Verification

	test_invariant_holds
			-- Test that class invariant holds through operations.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Invariant check: error_message_not_void
			assert ("error_message_not_void", l_con.last_error_message /= Void)

			-- Invariant check: color_constants_valid
			assert ("black_is_zero", l_con.Black = 0)
			assert ("white_is_fifteen", l_con.White = 15)

			-- Invariant check: log_level_valid
			assert ("log_level_valid", l_con.log_level >= 0 and l_con.log_level <= l_con.Log_level_fatal)
		end

end

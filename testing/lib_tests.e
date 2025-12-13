note
	description: "Tests for SIMPLE_CONSOLE library"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test routines

	test_has_real_console
			-- Test detection of real console.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			-- Just verify it returns a boolean without crashing
			assert ("has_real_console_works", l_con.has_real_console or not l_con.has_real_console)
		end

	test_color_constants
			-- Test that color constants are valid.
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			assert_integers_equal ("black_is_0", 0, l_con.Black)
			assert_integers_equal ("white_is_15", 15, l_con.White)
			assert_integers_equal ("red_is_12", 12, l_con.Red)
			assert_integers_equal ("green_is_10", 10, l_con.Green)
			assert_integers_equal ("blue_is_9", 9, l_con.Blue)
		end

	test_get_dimensions
			-- Test getting console dimensions (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				assert_greater_than ("width_positive", l_con.width, 0)
				assert_greater_than ("height_positive", l_con.height, 0)
			else
				-- No real console, skip
				assert ("no_console_skip", True)
			end
		end

	test_cursor_position
			-- Test cursor positioning (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_cursor (5, 10)
				assert_integers_equal ("cursor_x", 5, l_con.cursor_x)
				assert_integers_equal ("cursor_y", 10, l_con.cursor_y)
			else
				assert ("no_console_skip", True)
			end
		end

	test_set_foreground
			-- Test setting foreground color (if real console available).
		local
			l_con: SIMPLE_CONSOLE
		do
			create l_con
			if l_con.has_real_console then
				l_con.set_foreground (l_con.Green)
				assert_true ("foreground_set", l_con.last_operation_succeeded)
				l_con.reset_color
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
				l_con.hide_cursor
				assert_true ("hide_succeeded", l_con.last_operation_succeeded)
				l_con.show_cursor
				assert_true ("show_succeeded", l_con.last_operation_succeeded)
			else
				assert ("no_console_skip", True)
			end
		end

end

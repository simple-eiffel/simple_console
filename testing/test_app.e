note
	description: "Test application for simple_console library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the test suite - or, when given `Hidden_probe_option', act as
			-- the child process LIB_TESTS drives with a redirected standard input
			-- to exercise `SIMPLE_CONSOLE.read_hidden_line' for real.
		local
			tests: LIB_TESTS
			l_args: ARGUMENTS_32
		do
			create tests
			create l_args
			if l_args.argument_count >= 1 and then
				l_args.argument (1).same_string_general (tests.Hidden_probe_option)
			then
				run_hidden_line_probe
			elseif l_args.argument_count >= 1 and then
				l_args.argument (1).same_string_general (Hidden_demo_option)
			then
				run_hidden_line_demo
			else
				run_tests (tests)
			end
		end

	run_tests (tests: LIB_TESTS)
			-- Run tests.
		do
			io.put_string ("simple_console test runner%N")
			io.put_string ("==========================%N%N")

			passed := 0
			failed := 0

			-- Console Detection Tests
			io.put_string ("Console Detection Tests:%N")
			run_test (agent tests.test_has_real_console, "test_has_real_console")
			run_test (agent tests.test_default_creation, "test_default_creation")
			run_test (agent tests.test_make_creation, "test_make_creation")

			-- Color Constants Tests
			io.put_string ("%NColor Constants Tests:%N")
			run_test (agent tests.test_color_constants, "test_color_constants")
			run_test (agent tests.test_color_validation, "test_color_validation")
			run_test (agent tests.test_color_names, "test_color_names")

			-- Screen Dimensions Tests
			io.put_string ("%NScreen Dimensions Tests:%N")
			run_test (agent tests.test_get_dimensions, "test_get_dimensions")
			run_test (agent tests.test_dimensions_consistency, "test_dimensions_consistency")

			-- Cursor Operations Tests
			io.put_string ("%NCursor Operations Tests:%N")
			run_test (agent tests.test_cursor_position, "test_cursor_position")
			run_test (agent tests.test_cursor_origin, "test_cursor_origin")
			run_test (agent tests.test_cursor_visibility, "test_cursor_visibility")
			run_test (agent tests.test_cursor_position_query_no_console, "test_cursor_position_query_no_console")

			-- Color Operations Tests
			io.put_string ("%NColor Operations Tests:%N")
			run_test (agent tests.test_set_foreground, "test_set_foreground")
			run_test (agent tests.test_set_background, "test_set_background")
			run_test (agent tests.test_set_color_combined, "test_set_color_combined")
			run_test (agent tests.test_all_colors_foreground, "test_all_colors_foreground")
			run_test (agent tests.test_all_colors_background, "test_all_colors_background")
			run_test (agent tests.test_reset_color, "test_reset_color")

			-- Screen Operations Tests
			io.put_string ("%NScreen Operations Tests:%N")
			run_test (agent tests.test_clear_line, "test_clear_line")
			run_test (agent tests.test_set_title, "test_set_title")

			-- Convenience Methods Tests
			io.put_string ("%NConvenience Methods Tests:%N")
			run_test (agent tests.test_print_colored, "test_print_colored")
			run_test (agent tests.test_print_at, "test_print_at")
			run_test (agent tests.test_cli_output_helpers, "test_cli_output_helpers")

			-- Logging Tests
			io.put_string ("%NLogging Tests:%N")
			run_test (agent tests.test_logging_default_disabled, "test_logging_default_disabled")
			run_test (agent tests.test_enable_disable_logging, "test_enable_disable_logging")
			run_test (agent tests.test_set_log_level, "test_set_log_level")
			run_test (agent tests.test_log_level_constants, "test_log_level_constants")
			run_test (agent tests.test_logging_with_operations, "test_logging_with_operations")

			-- Error Handling Tests
			io.put_string ("%NError Handling Tests:%N")
			run_test (agent tests.test_error_message_cleared_on_success, "test_error_message_cleared_on_success")
			run_test (agent tests.test_error_handling_no_console, "test_error_handling_no_console")

			-- Hidden Line Input Tests
			io.put_string ("%NHidden Line Input Tests:%N")
			run_test (agent tests.test_is_stdin_console_is_answerable, "test_is_stdin_console_is_answerable")
			run_test (agent tests.test_hidden_line_redirected_ascii, "test_hidden_line_redirected_ascii")
			run_test (agent tests.test_hidden_line_redirected_crlf, "test_hidden_line_redirected_crlf")
			run_test (agent tests.test_hidden_line_redirected_unicode, "test_hidden_line_redirected_unicode")
			run_test (agent tests.test_hidden_line_redirected_end_of_input, "test_hidden_line_redirected_end_of_input")
			run_test (agent tests.test_hidden_line_redirected_empty_line, "test_hidden_line_redirected_empty_line")

			-- Invariant Tests
			io.put_string ("%NInvariant Verification Tests:%N")
			run_test (agent tests.test_invariant_holds, "test_invariant_holds")

			io.put_string ("%N==========================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	Hidden_demo_option: STRING = "--hidden-line-demo"
			-- Command-line option that runs `run_hidden_line_demo'.

	run_hidden_line_demo
			-- MANUAL check of the console path of `read_hidden_line' - the path no
			-- automated test in this suite can reach, because a test runner's
			-- standard input is a file or a pipe and this path needs a real
			-- console. Run it from cmd.exe or Windows Terminal, NOT through a pipe
			-- and NOT from a mintty shell such as git-bash:
			--
			--   EIFGENs/simple_console_tests/F_code/simple_console.exe --hidden-line-demo
			--
			-- What to look for:
			--   1. `is_stdin_console' reports True.
			--   2. NOTHING appears on screen while you type the first line.
			--   3. Backspace still erases, and Enter still ends the line.
			--   4. The code points reported back are the ones you typed - try a
			--      non-ASCII character if your keyboard can produce one.
			--   5. The SECOND line, read the ordinary way, DOES echo. That is the
			--      proof the console mode was put back.
		local
			l_con: SIMPLE_CONSOLE
			i: INTEGER
		do
			create l_con
			io.put_string ("is_stdin_console: " + l_con.is_stdin_console.out + "%N")
			io.put_string ("Secret (nothing should appear as you type): ")
			if attached l_con.read_hidden_line as l_line then
				io.put_string ("read " + l_line.count.out + " characters, code points:")
				from
					i := 1
				until
					i > l_line.count
				loop
					io.put_string (" " + l_line.code (i).out)
					i := i + 1
				end
				io.put_new_line
			else
				io.put_string ("end of input - nothing read%N")
			end
			io.put_string ("Echo check (this line SHOULD appear as you type): ")
			io.read_line
			io.put_string ("you typed " + io.last_string.count.out + " characters%N")
		end

	run_hidden_line_probe
			-- Read ONE line with `SIMPLE_CONSOLE.read_hidden_line' and report it on
			-- standard output as decimal code points, so the parent test can check
			-- every character without depending on the encoding this process's own
			-- output happens to use.
		local
			l_con: SIMPLE_CONSOLE
			l_report: STRING_8
			i: INTEGER
		do
			create l_con
			create l_report.make (64)
			l_report.append ("CONSOLE:" + l_con.is_stdin_console.out + "%N")
			if attached l_con.read_hidden_line as l_line then
				l_report.append ("LINE:" + l_line.count.out + ":")
				from
					i := 1
				until
					i > l_line.count
				loop
					if i > 1 then
						l_report.append_character (',')
					end
					l_report.append (l_line.code (i).out)
					i := i + 1
				end
				l_report.append_character ('%N')
			else
				l_report.append ("VOID%N")
			end
			io.put_string (l_report)
		end

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end

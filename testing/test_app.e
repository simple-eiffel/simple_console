note
	description: "Test application for simple_console library"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: LIB_TESTS
		do
			create tests
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

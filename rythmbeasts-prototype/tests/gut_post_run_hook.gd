extends GutHookScript
## GUT post-run hook that makes the command-line exit code reliable.
##
## GUT skips a test script that fails to load (parse or static typing error) with only a
## warning, and still exits with 0. This hook rejects the run, and exits with 1, when GUT
## logged any error or warning or when no test ran at all.

const EXIT_FAILURE: int = 1


func run() -> void:
	var totals: Dictionary = gut.get_summary().get_totals()
	var errors: int = totals.get(&"errors", 0)
	var warnings: int = totals.get(&"warnings", 0)
	var tests: int = totals.get(&"tests", 0)
	if errors > 0 or warnings > 0 or tests == 0:
		push_error("Test run rejected: %d GUT error(s), %d GUT warning(s), %d test(s)."
				% [errors, warnings, tests])
		set_exit_code(EXIT_FAILURE)

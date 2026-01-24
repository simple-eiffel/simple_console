# S01: PROJECT INVENTORY - simple_console

**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Library:** simple_console

## Project Structure

```
simple_console/
    src/
        simple_console.e        -- Main class
    testing/
        test_app.e              -- Test application
        lib_tests.e             -- Test suite
    include/
        simple_console.h        -- C wrapper header
    research/
        7S-01-SCOPE.md
        7S-02-STANDARDS.md
        7S-03-SOLUTIONS.md
        7S-04-SIMPLE-STAR.md
        7S-05-SECURITY.md
        7S-06-SIZING.md
        7S-07-RECOMMENDATION.md
    specs/
        S01-PROJECT-INVENTORY.md
        S02-CLASS-CATALOG.md
        S03-CONTRACTS.md
        S04-FEATURE-SPECS.md
        S05-CONSTRAINTS.md
        S06-BOUNDARIES.md
        S07-SPEC-SUMMARY.md
        S08-VALIDATION-REPORT.md
    simple_console.ecf          -- Project configuration
```

## File Inventory

| File | Type | Lines | Purpose |
|------|------|-------|---------|
| simple_console.e | Source | 620 | Main console class |
| test_app.e | Test | ~50 | Test runner |
| lib_tests.e | Test | ~150 | Test cases |
| simple_console.h | C Header | ~150 | Win32 wrapper |

## External Dependencies

| Dependency | Type | Location |
|------------|------|----------|
| Kernel32.dll | System | Windows |
| simple_logger | Library | Optional |
| EiffelBase | Library | ISE_LIBRARY |

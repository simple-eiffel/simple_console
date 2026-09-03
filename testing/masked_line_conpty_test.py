"""Headless ConPTY check of SIMPLE_CONSOLE.read_masked_line's REAL-console path.

No redirected-stdin test in lib_tests.e/test_app.e can reach this path: it
needs `is_stdin_console' to be True, and a test runner's own standard input
is a file or a pipe. A Windows pseudoconsole (ConPTY, via the `pywinpty'
package) gives the child process a REAL console handle - `GetConsoleMode'
succeeds on it - without ever creating a visible window or taking focus on
the desktop. That is exactly why this script exists and why it is safe to
run unattended: nothing appears on screen, and no keystrokes reach any
window a person might be typing into.

What it does:
    1. Spawns `simple_console.exe --masked-line-demo' inside a ConPTY.
    2. Waits for the "Password" prompt.
    3. Sends the keystrokes  a  b  c  <Backspace>  d  <Enter>  - and then a
       second <Enter> to satisfy the demo's own echo-check line, so the
       child exits on its own instead of being killed.
    4. Parses everything the child wrote to the pty between the prompt and
       the newline that follows it: the RAW byte sequence a real terminal
       received is itself the proof of what happened on screen, in order -
       `***' for the three characters typed, then `\x08 \x08' (backspace,
       space, backspace) for the one character erased, then `*' for the
       fourth. That yields the visible-mask-count trajectory this script
       asserts on: 1, 2, 3, 2, 3 - three masks, then two, then three again,
       and at no point four (which would mean Backspace failed to erase).
    5. Asserts the code points the feature reported back are exactly
       97, 98, 100 - 'a', 'b', 'd' - proving Backspace removed 'c' and nothing
       else, and asserts the literal string "abcd" never appears anywhere in
       the captured output.

Usage:
    py -3 testing\\masked_line_conpty_test.py
    (or: python testing/masked_line_conpty_test.py)

Exit code 0 and "PASS" on success; exit code 1 and a description of what
went wrong otherwise. Requires `pywinpty' (`pip install --user pywinpty').
"""

import os
import queue
import sys
import threading
import time

try:
    import winpty
except ImportError:
    sys.stderr.write(
        "pywinpty is not installed. Install it with:\n"
        "    pip install --user pywinpty\n"
    )
    sys.exit(2)

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_EXE = os.path.normpath(
    os.path.join(THIS_DIR, "..", "EIFGENs", "simple_console_tests", "F_code", "simple_console.exe")
)

BACKSPACE_KEY = "\x7f"  # DEL - what a terminal conventionally sends for the
                        # Backspace key over ConPTY's VT input; confirmed
                        # empirically against this build to reach VK_BACK.
PROMPT = "Password (each character prints as *): "
CONSOLE_LINE = "is_stdin_console: True"


def _reader_thread(proc, out_queue):
    """Continuously pull bytes from the pty into `out_queue' until EOF."""
    try:
        while True:
            chunk = proc.read(4096)
            if not chunk:
                break
            out_queue.put(chunk)
    except EOFError:
        pass
    finally:
        out_queue.put(None)  # sentinel: no more data will ever arrive


def _drain(out_queue, buffer_parts, quiet_seconds=0.6, max_wait_seconds=8.0):
    """Pull everything currently available from `out_queue' into
    `buffer_parts', stopping once `quiet_seconds' have passed with nothing
    new, or `max_wait_seconds' total have elapsed - whichever comes first.
    ConPTY batches its output on its own schedule, not the caller's, so this
    waits for a quiet period rather than a fixed sleep."""
    start = time.time()
    last_data = time.time()
    while True:
        try:
            item = out_queue.get(timeout=0.05)
        except queue.Empty:
            item = None
        if item is not None:
            buffer_parts.append(item)
            last_data = time.time()
        now = time.time()
        if now - last_data >= quiet_seconds:
            return
        if now - start >= max_wait_seconds:
            return


def _wait_for(out_queue, buffer_parts, needle, max_wait_seconds=8.0):
    """Drain repeatedly until `needle' appears in the accumulated text, or
    `max_wait_seconds' elapses. Returns the accumulated text so far."""
    start = time.time()
    while True:
        _drain(out_queue, buffer_parts, quiet_seconds=0.15, max_wait_seconds=1.0)
        text = "".join(buffer_parts)
        if needle in text:
            return text
        if time.time() - start >= max_wait_seconds:
            return text


def mask_trajectory(masked_region, mask="*"):
    """The running count of visible mask characters after each mask/erase
    event in `masked_region', in order. A mask character increments it; the
    exact three-byte erase sequence this library's C code writes for
    Backspace - backspace, space, backspace - decrements it. Every other
    byte is ignored, so surrounding prompt text or terminal negotiation
    sequences cannot throw the count off."""
    trajectory = []
    visible = 0
    i = 0
    n = len(masked_region)
    while i < n:
        c = masked_region[i]
        if c == mask:
            visible += 1
            trajectory.append(visible)
            i += 1
        elif masked_region[i:i + 3] == "\x08 \x08":
            visible = max(0, visible - 1)
            trajectory.append(visible)
            i += 3
        else:
            i += 1
    return trajectory


def main():
    exe = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_EXE
    if not os.path.isfile(exe):
        sys.stderr.write("FAIL: executable not found: %s\n" % exe)
        sys.stderr.write("Build it first:\n")
        sys.stderr.write("  ec.sh test -config simple_console.ecf -target simple_console_tests\n")
        return 1

    proc = winpty.PtyProcess.spawn([exe, "--masked-line-demo"], dimensions=(24, 80))
    out_queue = queue.Queue()
    reader = threading.Thread(target=_reader_thread, args=(proc, out_queue), daemon=True)
    reader.start()

    buffer_parts = []
    text = _wait_for(out_queue, buffer_parts, PROMPT, max_wait_seconds=10.0)
    if CONSOLE_LINE not in text:
        sys.stderr.write("FAIL: %r never reported - got:\n%r\n" % (CONSOLE_LINE, text))
        return 1
    if PROMPT not in text:
        sys.stderr.write("FAIL: password prompt never appeared - got:\n%r\n" % text)
        return 1

    # a, b, c, Backspace, d, Enter - then a second Enter for the demo's own
    # echo-check line, so the child exits on its own.
    for key in ["a", "b", "c", BACKSPACE_KEY, "d", "\r"]:
        proc.write(key)
        time.sleep(0.12)

    text = _wait_for(out_queue, buffer_parts, "code points:", max_wait_seconds=10.0)

    proc.write("\r")
    _drain(out_queue, buffer_parts, quiet_seconds=0.5, max_wait_seconds=5.0)
    text = "".join(buffer_parts)

    try:
        if proc.isalive():
            proc.terminate(force=True)
    except Exception:
        pass

    failures = []

    if "abcd" in text:
        failures.append("the literal sequence 'abcd' appeared in the captured output - "
                         "a character the user typed was echoed instead of masked")

    prompt_index = text.find(PROMPT)
    if prompt_index == -1:
        failures.append("password prompt not found in final captured output")
        masked_region = ""
    else:
        rest = text[prompt_index + len(PROMPT):]
        end_index = rest.find("\r\n")
        masked_region = rest if end_index == -1 else rest[:end_index]

    trajectory = mask_trajectory(masked_region)
    expected_trajectory = [1, 2, 3, 2, 3]
    if trajectory != expected_trajectory:
        failures.append(
            "mask trajectory was %r, expected %r (three masks, then two, then three) - "
            "raw masked region: %r" % (trajectory, expected_trajectory, masked_region)
        )

    if "code points: 97 98 100" not in text:
        failures.append(
            "expected 'code points: 97 98 100' (a, b, d) in output - got:\n%r" % text
        )

    if failures:
        sys.stderr.write("FAIL:\n")
        for f in failures:
            sys.stderr.write("  - " + f + "\n")
        sys.stderr.write("\nFull captured output:\n%r\n" % text)
        return 1

    print("PASS: masked_region=%r trajectory=%r" % (masked_region, trajectory))
    print("PASS: code points reported were 97 98 100 (a, b, d) - Backspace removed 'c' cleanly")
    print("PASS: 'abcd' never appeared in the captured output")
    return 0


if __name__ == "__main__":
    sys.exit(main())

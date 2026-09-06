#!/bin/bash
# c05 — The Pipeline / test.sh
#
# Tests pipeline — a program that executes < infile cmd1 | cmd2 | ... | cmdN > outfile.
# Copy this file into your working directory, build the binary with 'make re', then run:
#
#   bash test.sh

set -o pipefail

# ── colour ────────────────────────────────────────────────────────────────────

if [[ ! -t 1 ]]; then
    C_GREEN=""
    C_RED=""
    C_BOLD=""
    C_RESET=""
else
    C_GREEN="\033[0;32m"
    C_RED="\033[0;31m"
    C_BOLD="\033[1m"
    C_RESET="\033[0m"
fi

# ── state ─────────────────────────────────────────────────────────────────────

pass_count=0
fail_count=0
WORK_DIR=$(mktemp -d)

# ── cleanup ───────────────────────────────────────────────────────────────────

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ── helpers ───────────────────────────────────────────────────────────────────

hr() {
    echo "────────────────────────────────────────────────────────────────"
}

banner() {
    hr
    echo "  c05 — The Pipeline / test.sh"
    hr
}

pass() {
    local label="$1"
    printf "  ${C_GREEN}PASS${C_RESET}  %s\n" "$label"
    pass_count=$((pass_count + 1))
}

fail() {
    local label="$1"
    local detail="${2:-}"
    printf "  ${C_RED}FAIL${C_RESET}  %s\n" "$label"
    if [[ -n "$detail" ]]; then
        printf "    %s\n" "$detail"
    fi
    fail_count=$((fail_count + 1))
}

# check_pipeline: run ./pipeline and the shell oracle; diff outfile vs oracle.
# Usage: check_pipeline label infile oracle_cmd pipeline_cmds...
#   infile        — input file path
#   oracle_cmd    — bash -c string (no redirects; reads from stdin)
#   pipeline_cmds — one or more quoted command strings for ./pipeline
# The last pipeline_cmd is the final argument; outfile is appended automatically.
check_pipeline() {
    local label="$1"
    local infile="$2"
    local oracle="$3"
    shift 3

    local got="${WORK_DIR}/got.txt"
    local expected="${WORK_DIR}/expected.txt"

    bash -c "$oracle" < "$infile" > "$expected" 2>/dev/null
    ./pipeline "$infile" "$@" "$got" > /dev/null 2>&1

    if diff -q "$expected" "$got" > /dev/null 2>&1; then
        pass "$label"
    else
        fail "$label"
        diff --unified=1 "$expected" "$got" | tail -n +4 | \
            head -10 | while IFS= read -r line; do printf "    %s\n" "$line"; done
    fi
}

# check_heredoc: feed input through heredoc form and diff against oracle.
# Usage: check_heredoc label limiter input oracle_cmd pipeline_cmds...
#   input      — text lines fed before the limiter (no trailing newline needed)
#   oracle_cmd — bash -c string that processes the same input
check_heredoc() {
    local label="$1"
    local limiter="$2"
    local input="$3"
    local oracle="$4"
    shift 4

    local got="${WORK_DIR}/got.txt"
    local expected="${WORK_DIR}/expected.txt"

    # a heredoc always terminates its last line, so the oracle must see one too
    printf '%s\n' "$input" | bash -c "$oracle" > "$expected" 2>/dev/null
    printf '%s\n%s\n' "$input" "$limiter" | ./pipeline "$limiter" "$@" "$got" > /dev/null 2>&1

    if diff -q "$expected" "$got" > /dev/null 2>&1; then
        pass "$label"
    else
        fail "$label"
        diff --unified=1 "$expected" "$got" | tail -n +4 | \
            head -10 | while IFS= read -r line; do printf "    %s\n" "$line"; done
    fi
}

# check_exit: run ./pipeline and assert its exit code.
check_exit() {
    local label="$1"
    local expected_code="$2"
    shift 2

    ./pipeline "$@" > /dev/null 2>&1
    local actual=$?

    if [[ $actual -eq $expected_code ]]; then
        pass "$label (exit $actual)"
    else
        fail "$label" "expected exit $expected_code, got $actual"
    fi
}

# ── pre-flight ────────────────────────────────────────────────────────────────

preflight() {
    local ok=1
    if [[ ! -x ./pipeline ]]; then
        echo "error: ./pipeline not found or not executable — run 'make re' first" >&2
        ok=0
    fi
    for tool in diff wc sort uniq cat; do
        if ! command -v "$tool" &>/dev/null; then
            echo "error: $tool is not installed" >&2
            ok=0
        fi
    done
    if [[ $ok -eq 0 ]]; then
        exit 1
    fi
}

# ── fixtures ──────────────────────────────────────────────────────────────────

make_fixtures() {
    # lines.txt — four distinct lines
    printf 'delta\nalpha\nbeta\ngamma\n' > "${WORK_DIR}/lines.txt"

    # words.txt — duplicates for sort | uniq tests
    printf 'delta\nalpha\nbeta\ngamma\nalpha\ndelta\n' > "${WORK_DIR}/words.txt"

    # empty.txt — zero bytes
    : > "${WORK_DIR}/empty.txt"
}

# ── single command ────────────────────────────────────────────────────────────

run_single_suite() {
    echo ""
    echo "${C_BOLD}  single command${C_RESET}"
    echo ""

    local lines="${WORK_DIR}/lines.txt"
    local words="${WORK_DIR}/words.txt"

    check_pipeline "cat" "$lines" "cat" "cat"
    check_pipeline "wc -l" "$lines" "wc -l" "wc -l"
    check_pipeline "sort" "$words" "sort" "sort"
    check_pipeline "cat (empty input)" "${WORK_DIR}/empty.txt" "cat" "cat"
}

# ── two commands ──────────────────────────────────────────────────────────────

run_two_command_suite() {
    echo ""
    echo "${C_BOLD}  two commands${C_RESET}"
    echo ""

    local lines="${WORK_DIR}/lines.txt"
    local words="${WORK_DIR}/words.txt"

    check_pipeline "cat | wc -l"    "$lines" "cat | wc -l"    "cat" "wc -l"
    check_pipeline "cat | wc -c"    "$lines" "cat | wc -c"    "cat" "wc -c"
    check_pipeline "sort | uniq"    "$words" "sort | uniq"    "sort" "uniq"
    check_pipeline "cat | sort"     "$words" "cat | sort"     "cat" "sort"
}

# ── three-command chain ───────────────────────────────────────────────────────

run_chain_suite() {
    echo ""
    echo "${C_BOLD}  three-command chain${C_RESET}"
    echo ""

    local words="${WORK_DIR}/words.txt"

    check_pipeline "cat | sort | uniq" \
        "$words" "cat | sort | uniq" "cat" "sort" "uniq"

    check_pipeline "sort | uniq | wc -l" \
        "$words" "sort | uniq | wc -l" "sort" "uniq" "wc -l"
}

# ── heredoc ───────────────────────────────────────────────────────────────────

run_heredoc_suite() {
    echo ""
    echo "${C_BOLD}  heredoc${C_RESET}"
    echo ""

    local input
    input="$(printf 'alpha\nbeta\ngamma\n')"

    check_heredoc "heredoc: cat" \
        "STOP" "$input" "cat" "cat"

    check_heredoc "heredoc: cat | wc -l" \
        "STOP" "$input" "cat | wc -l" "cat" "wc -l"

    check_heredoc "heredoc: sort | uniq" \
        "STOP" "$(printf 'beta\nalpha\nbeta\ngamma\n')" "sort | uniq" "sort" "uniq"
}

# ── error handling ────────────────────────────────────────────────────────────

run_error_suite() {
    echo ""
    echo "${C_BOLD}  error handling${C_RESET}"
    echo ""

    local lines="${WORK_DIR}/lines.txt"
    local got="${WORK_DIR}/got.txt"

    # bad infile: must exit non-zero without creating outfile.
    # The file has to EXIST but be unopenable: under the two-form CLI a first
    # argument that does not exist is a heredoc LIMITER, not a broken infile.
    rm -f "${WORK_DIR}/bad_infile_out.txt"
    : > "${WORK_DIR}/unreadable_infile.txt"
    chmod 000 "${WORK_DIR}/unreadable_infile.txt"
    ./pipeline "${WORK_DIR}/unreadable_infile.txt" "cat" \
        "${WORK_DIR}/bad_infile_out.txt" > /dev/null 2>&1
    local code=$?
    if [[ $code -ne 0 ]]; then
        pass "bad infile: exits non-zero (exit $code)"
    else
        fail "bad infile: exits non-zero" "got exit 0"
    fi

    # bad outfile: must exit non-zero
    ./pipeline "$lines" "cat" "/no/such/dir/out.txt" > /dev/null 2>&1
    code=$?
    if [[ $code -ne 0 ]]; then
        pass "bad outfile: exits non-zero (exit $code)"
    else
        fail "bad outfile: exits non-zero" "got exit 0"
    fi

    # command not found: must exit 127
    check_exit "command not found: exit 127" 127 \
        "$lines" "nosuchcmd_tci_xyz_42" "$got"
}

# ── exit status ───────────────────────────────────────────────────────────────

run_exit_status_suite() {
    echo ""
    echo "${C_BOLD}  exit status${C_RESET}"
    echo ""

    local lines="${WORK_DIR}/lines.txt"
    local got="${WORK_DIR}/got.txt"

    # last command exits 0 — pipeline exits 0
    check_exit "last command exit 0 (true)" 0 \
        "$lines" "cat" "true" "$got"

    # last command exits 1 (false) — pipeline exits 1
    check_exit "last command exit 1 (false)" 1 \
        "$lines" "cat" "false" "$got"

    # command not found as last — exit 127 regardless of earlier commands
    check_exit "last command not found: exit 127" 127 \
        "$lines" "cat" "nosuchcmd_tci_xyz_42" "$got"
}

# ── summary ───────────────────────────────────────────────────────────────────

summary() {
    local total=$((pass_count + fail_count))
    echo ""
    hr
    printf "  %d / %d tests passed\n" "$pass_count" "$total"
    hr
    echo ""
    if [[ $fail_count -gt 0 ]]; then
        exit 1
    fi
}

# ── main ──────────────────────────────────────────────────────────────────────

banner
preflight
make_fixtures
run_single_suite
run_two_command_suite
run_chain_suite
run_heredoc_suite
run_error_suite
run_exit_status_suite
# ── leak report ─────────────────────────────────────────────────────────────
#
# Runs one representative invocation under valgrind and REPORTS what it finds.
# It never changes the pass/fail count. A leak is something to look at, not a
# reason to refuse your work — but you should see it, because a program that
# leaks is a program that will eventually be killed by the machine it runs on.
#
# Leaks are split by whose code lost the memory. A loss record whose stack
# names one of your own .c files is yours. One that lives entirely inside
# SDL, Mesa or glibc is not, and there is nothing for you to fix there.

leak_report() {
    local label="$1"; shift
    local log="${WORK_DIR:-/tmp}/leaks.$$.log"
    local mine=0 theirs=0 rec frames

    if ! command -v valgrind >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind is not installed, skipping\n" "$label"
        return 0
    fi

    valgrind --leak-check=full --show-leak-kinds=definite,indirect \
             --error-exitcode=0 --log-file="$log" "$@" >/dev/null 2>&1

    if [[ ! -s "$log" ]]; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind produced no output\n" "$label"
        return 0
    fi

    # Split the log into loss records and ask, of each, whether any frame
    # points at a source file sitting in this directory.
    while IFS= read -r rec; do
        frames=$(sed -n "${rec}"',/^==[0-9]*== *$/p' "$log")
        # Every record carries valgrind's own malloc frame; that is not yours.
        # A frame is yours only if it names a source file sitting right here.
        local f owned=0
        for f in $(grep -oE '\(([A-Za-z0-9_-]+\.c):[0-9]+\)' <<<"$frames" \
                   | tr -d '()' | cut -d: -f1 | sort -u); do
            [[ "$f" == vg_replace_malloc.c ]] && continue
            [[ -f "$f" ]] && owned=1
        done
        if (( owned )); then
            mine=$((mine + 1))
            if (( mine == 1 )); then
                printf "  ${C_RED}LEAK${C_RESET}  %s — memory lost by your code:\n" "$label"
            fi
            grep -E 'bytes in [0-9,]+ blocks are (definitely|indirectly)' <<<"$frames" \
                | sed 's/^==[0-9]*== /        /'
            grep -oE '\(([A-Za-z0-9_-]+\.c:[0-9]+)\)' <<<"$frames" \
                | grep -v vg_replace_malloc | head -3 | tr -d '()' \
                | sed 's/^/          at /'
        else
            theirs=$((theirs + 1))
        fi
    done < <(grep -nE 'bytes in [0-9,]+ blocks are (definitely|indirectly) lost' "$log" | cut -d: -f1)

    if (( mine == 0 )); then
        printf "  ${C_GREEN}OK${C_RESET}    %s — no memory lost by your code" "$label"
        if (( theirs > 0 )); then
            printf ' (%d leak(s) inside libraries you did not write)' "$theirs"
        fi
        printf '\n'
    else
        printf '        this does not fail the tester — fix it anyway\n'
    fi
    rm -f "$log"
    return 0
}

# The graphical chapters run until you quit them, and a program killed
# mid-loop reports everything it has not freed yet as "lost" -- which would be
# a lie. So this starts a virtual display, lets the program run, sends it a
# 'q', and measures the clean exit.
leak_report_gui() {
    local label="$1"; shift
    if ! command -v valgrind >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind is not installed, skipping\n" "$label"
        return 0
    fi
    if ! command -v xvfb-run >/dev/null 2>&1 || ! command -v xte >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: needs xvfb-run and xte for a clean exit, skipping\n" "$label"
        return 0
    fi
    printf "  ${C_BOLD}....${C_RESET}  %s: running under valgrind, this takes a minute\n" "$label"
    local inner="${WORK_DIR:-/tmp}/leak_gui.$$.sh"
    {
        echo "C_GREEN=\"${C_GREEN}\"; C_RED=\"${C_RED}\"; C_BOLD=\"${C_BOLD}\"; C_RESET=\"${C_RESET}\""
        echo "WORK_DIR=\"${WORK_DIR:-/tmp}\""
        declare -f leak_report
        echo '( sleep 12; xte "key q" 2>/dev/null; sleep 5; xte "key q" 2>/dev/null ) &'
        printf 'leak_report %q' "$label"
        printf ' %q' "$@"
        printf '\n'
    } > "$inner"
    timeout 240 xvfb-run -a bash "$inner"
    local rc=$?
    rm -f "$inner"
    if (( rc == 124 )); then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: the program never exited, so there is nothing honest to measure\n" "$label"
        printf "        (a program killed mid-loop reports everything it holds as lost)\n"
    fi
    return 0
}

echo
: > /tmp/_leak_in.txt; printf 'alpha\nbeta\n' > /tmp/_leak_in.txt
leak_report "pipeline" ./pipeline /tmp/_leak_in.txt "cat" /tmp/_leak_out.txt

summary

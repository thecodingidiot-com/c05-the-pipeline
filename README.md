# c05-the-pipeline

Companion repository for **c05 — The Pipeline** at
[thecodingidiot.com](https://thecodingidiot.com).

---

## Follow my journey

Working through c05 alongside the implementation pages? Build `pipeline`
step by step, then run the tester.

Clone this repository and copy `test.sh` into your working directory:

```bash
git clone https://github.com/thecodingidiot-com/c05-the-pipeline.git
cp c05-the-pipeline/test.sh ~/c05-practice/
cd ~/c05-practice
make re
bash test.sh
```

All tests must pass before the chapter is complete.

---

## Follow your journey

Building `pipeline` independently? Here is the full project brief.

The program accepts two forms:

```bash
./pipeline infile "cmd1 [args]" "cmd2 [args]" ... "cmdN [args]" outfile
./pipeline "LIMITER" "cmd1 [args]" "cmd2 [args]" ... "cmdN [args]" outfile
```

**Rules:**

- Open `infile` for reading; `dup2` its file descriptor to cmd1's stdin.
  For the heredoc form, read stdin lines until a line matching LIMITER
  appears and write them to a pipe; `dup2` the read end to cmd1's stdin.
- Open or create `outfile` for writing (`O_WRONLY | O_CREAT | O_TRUNC`,
  mode `0644`); `dup2` its file descriptor to cmdN's stdout.
- Allocate N−1 pipes using `pipe()`. Connect each cmdK's stdout to
  cmdK+1's stdin via `dup2`.
- Fork N child processes. Set each child's stdin and stdout before
  calling `execve`. Close all pipe ends in every process before executing.
- Execute each command with `execve`. Search `PATH` by splitting
  `getenv("PATH")` on `:` and prepending each directory.
- Wait for all children. Exit with cmdN's exit status.
- If a command is not found or not executable, exit 127.
- If `infile` cannot be opened, exit 1 without forking.
- If `outfile` cannot be opened or created, exit 1 without forking.
- Represent the command chain as a `t_list` of `char **` argv arrays.

Source is split across three files:

| File | Contents |
| --- | --- |
| `main.c` | argument validation, heredoc detection, list construction, top-level orchestration, cleanup |
| `exec.c` | PATH search, `execve` wrapper, exit-127 handling |
| `pipeline.c` | pipe allocation, `dup2` routing, fork loop, wait loop |

Build links against `libtci.a` and `libtciutil.a` from your working
directory.

Build and test your own version first. Use `solution/` to compare once
you are done, not before.

---

## Building the solution

The `solution/` Makefile expects `libtci.a`, `libtciutil.a`, `libtci.h`,
and `libtciutil.h` to be present in the `solution/` directory. Copy them
from your working directory:

```bash
cp libtci.a libtciutil.a libtci.h libtciutil.h c05-the-pipeline/solution/
cd c05-the-pipeline/solution
make
```

---

## What the tester checks

**Single command** — `./pipeline infile "cat" outfile` and variants.
Verifies infile and outfile redirects with one command.

**Two commands** — `cat | wc -l`, `cat | wc -c`, `sort | uniq`,
`cat | sort`. Verifies the pipe between two commands.

**Three-command chain** — `cat | sort | uniq`, `sort | uniq | wc -l`.
Verifies the generalised N-command loop.

**Heredoc** — LIMITER form with `cat`, `cat | wc -l`, `sort | uniq`.
Verifies that heredoc input reaches cmd1's stdin correctly.

**Error cases:**
- Bad infile: exits non-zero and does not produce output.
- Bad outfile: exits non-zero.
- Command not found: exits 127.

**Exit status** — the exit code of cmdN is the exit code of `./pipeline`.
Tests with `true` (exit 0), `false` (exit 1), and a missing command (exit 127).

---

## License

MIT License. See [LICENSE](LICENSE).

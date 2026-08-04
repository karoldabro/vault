---
type: indication
project: vault
slug: gate-prompts-on-stdin-tty
scope: repo
tags: [indication, install, shell, testing]
---

# gate-prompts-on-stdin-tty

## Rule
Gate every interactive prompt in a script on **`[ -t 0 ]`** — stdin being a terminal — before reading
from `/dev/tty`. A readable `/dev/tty` alone is not evidence that anyone is there to answer. Every
prompt needs a defined non-interactive branch, and that branch must be the conservative one.

## Rationale
A piped or scripted run (`curl … | bash`, CI, the bats suite) still has a controlling terminal, so a
`/dev/tty`-only check passes and the script blocks forever on a question nobody will answer. `[ -t 0 ]`
is false in exactly those cases.

It is also the difference between a testable path and an untestable one: with the `[ -t 0 ]` gate,
`</dev/null` deterministically reaches the non-interactive branch, so it can be asserted on. Without it,
a test that reaches the prompt hangs the suite when run from a terminal and passes when run from CI.

Testing the interactive branch is a separate job and needs a real pty — `script -qec "<cmd>" /dev/null`
with the answer on stdin. Piping an answer in exercises the *scripted* branch, not the prompt.

## Examples
Do — `setup.sh` profile selection:

```bash
if [ "${assume_yes}" -eq 1 ]; then
    profile="light"
elif [ -t 0 ] && { : </dev/tty; } 2>/dev/null; then
    printf 'Choice [1]: '
    read -r reply </dev/tty || reply=""
else
    profile="minimal"          # conservative: install nothing unattended
    warn "No answer and no consent — installing no tools."
fi
```

Don't:

```bash
# Hangs under `curl | bash` and in any suite run from a terminal.
if read -r reply </dev/tty 2>/dev/null; then ...
```

Also don't print the prompt before discovering there is no terminal — the menu ends up in a log
followed by "no answer", which reads as a bug.

## Applies-to
`setup.sh`, `install.sh`, `bin/*.sh`, `lib/installers.sh` — any script with a consent gate or a
choice prompt.

---
type: indication
project: vault
slug: pin-pipx-python
scope: repo
tags: [indication]
---

# pin-pipx-python

## Rule
When installing a pipx tool that has a Python version floor, **pin the interpreter** with
`pipx install <pkg> --python <pythonX.Y>` (a `>=3.10` interpreter for this stack's tools). Never rely
on the host's default `python3`. If no qualifying interpreter exists, fail with the real reason + the
command to install one — don't let pip's cryptic error stand.

## Rationale
pipx builds each tool's venv with whatever `python3` it finds. A package that requires a newer Python
than that interpreter resolves to **zero** candidate versions, and (older) pip reports it as
`No matching distribution found / from versions: none` — which reads as "the package doesn't exist"
even though it's on PyPI. This bit a WSL/Ubuntu-20.04 box (Python 3.8) where `openviking`/`graphifyy`
(both `>=3.10`) failed while `uv`/`bun` succeeded. The "only the pipx tools fail" pattern is the tell.

## Examples
- Do: `pick_python` selects `python3.13..3.10`; `pipx_install` passes it via `--python`
  (`lib/installers.sh`).
- Do: when none is found → `warn` with `apt-get install -y python3.12 python3.12-venv` and return 1.
- Don't: `pipx install openviking` (inherits the default `python3`, may be 3.8 → fails opaquely).
- Doctor surfaces a `python >=3.10 (pipx)` row.

## Applies-to
`lib/installers.sh` (`pick_python`, `pipx_install`), `setup.sh`, any pipx-installed tool

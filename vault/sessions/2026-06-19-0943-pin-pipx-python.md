---
type: session
project: vault
date: 2026-06-19
topic: pin pipx tools to Python >=3.10 in the installer
files_touched: [setup.sh, lib/installers.sh, tests/unit/setup-autoinstall.bats, README.md]
decisions: [pin-pipx-python]
continues: [[2026-06-19-0924-settings-env-and-uninstall]]
tags: [session, installer, pipx, python, bugfix]
---

# pin pipx tools to Python >=3.10 in the installer

## Goal
Fix `setup.sh` so the pipx-installed tools (openviking, graphifyy) don't fail with "No matching
distribution found" on hosts with an old default Python.

## Did
- Diagnosed a third machine (przemekp, WSL): `pipx install openviking` / `graphifyy` both failed with
  `Could not find a version that satisfies the requirement … (from versions: none)`, while
  ollama/uv/bun/serena succeeded. Verified both packages **are** public on PyPI (openviking 0.4.4,
  graphifyy 0.8.42) and only require **Python >=3.10**. Conclusion: pipx was building the venv with an
  old `python3` (WSL/Ubuntu 20.04 = 3.8), so every version was filtered out → the cryptic pip error.
- Added `pick_python` to [[lib/installers.sh]]: echoes the first `python3.13..3.10` (then `python3`/
  `python`) on PATH that is >=3.10, else returns 1. Added `pipx_install <pkg>` that passes the picked
  interpreter via `--python`; under dry-run it echoes a representative command for transcript
  stability, and on a real run with no >=3.10 interpreter it **fails loudly** with the apt command to
  fix it instead of the opaque pip error.
- Switched `install_openviking_server` + `install_graphify` to `pipx_install`. Doctor gained a
  `python >=3.10 (pipx)` row. Updated the printed hints to show `--python python3.12`.
- Tests: +2 unit (dry-run transcript pins `--python`; `pick_python` accepts 3.12, rejects 3.8 via
  stubbed interpreters). Offline suite green (39 unit + 50 integration = 89, 0 fail). Committed
  `563f328`, pushed to main.

## Learned
- pipx builds each tool's venv with the **default `python3`**; a package requiring a newer Python than
  that interpreter resolves to **zero** candidates, and older pip reports it as "No matching
  distribution found / from versions: none" (no "ignored versions" hint) — easy to misread as "package
  doesn't exist." Always pin `--python` for pipx tools with a version floor.
- The tell that it's a Python-version problem and not a registry/network one: the `uv`/`bun`/`curl|sh`
  tools install fine; only the **pipx** tools fail. Different interpreter path.
- Three onboarding machines this session exposed three distinct installer gaps (sudo model, OV server
  + configs, Windows CRLF, now Python floor) — each invisible on the already-working dev box.

## Next
- przemekp: `sudo apt install -y python3.12 python3.12-venv`, then `git pull && ./setup.sh --full
  --yes` → openviking-server / :1933 / graphify should go ✓.

## Refs
- [[../decisions/ADR-005-installer-auto-exec]]
- [[../indications/openviking-three-part-install]]
- [[../indications/pin-pipx-python]]
- [[2026-06-19-0924-settings-env-and-uninstall]]

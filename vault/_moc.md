---
type: moc
project: vault
tags: [moc]
---

# vault — Map of Contents

## Coupled with
<!-- Sibling projects. e.g., - [[../<other-project>/_moc]] (api shares contracts) -->

## Decisions
<!-- Auto: link to [[decisions/]] folder. Notable ADRs: -->
- [[decisions/ADR-001-panel-loop-over-peer-debate]] · [[decisions/ADR-002-no-stop-on-approval-alone]] · [[decisions/ADR-003-tool-grounded-findings]] · [[decisions/ADR-004-generic-packs-specifics-in-indications]] · [[decisions/ADR-005-installer-auto-exec]] · [[decisions/ADR-006-testing-critic-group]]

## Indications
- See [[indications/_index]] — v-team authoring rules (persona factoring, loop stops, grounded findings)

## Features
<!-- Link to [[features/]] folder. Active features: -->
- [[features/v-team]] — persona-critique dev lifecycle command
- Testing critic group — `personas/_shared/testing/` (6 lenses for AI-written tests); see [[indications/testing-persona-group]]

## Sessions (recent)
<!-- Last N session entries appended by /save or OV auto-capture. -->
- [[sessions/2026-06-19-0954-testing-persona-group]] — add a 6-persona testing critic group to /v-team (panel-built, research-grounded)
- [[sessions/2026-06-19-0943-pin-pipx-python]] — pin pipx tools to Python >=3.10 (fixes "No matching distribution")
- [[sessions/2026-06-19-0924-settings-env-and-uninstall]] — settings.json env for the OV plugin + new vault-uninstall.sh
- [[sessions/2026-06-19-0901-openviking-server-installer]] — setup.sh installs the OV server + configs, not just the plugin
- [[sessions/2026-06-19-0831-setup-sudo-deadlock-fix]] — fix setup.sh sudo deadlock; per-user run auto-installs, refuse `sudo`

## Code
- Graph: `graphify/<repo>/graph.json` per sub-repo.
- Repo roots: `<path-to-repo>`.

## External refs
<!-- Links to source repos at `/media/...` or `/home/.../workspace/...`. -->

## Start Here
- Process docs: `/home/kdabrow/workspace/vault/vault-guide.md` (global framework install)

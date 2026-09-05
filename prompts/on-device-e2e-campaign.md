# Bootstrapping an on-device E2E campaign

Reusable prompt for standing up exhaustive end-to-end coverage of a mobile app on a real phone, against a real backend, resumable across session usage limits.

Written from the Givore Flutter campaign (2026-09-05). Every warning below cost a real debugging session; none is hypothetical.

---

## The prompt

> Set up a resumable on-device end-to-end test campaign for `<app>` at `<repo path>`.
>
> The phone is connected over adb. The app is installed. The backend is `<dev API URL>` and I am free to modify it.
>
> Credentials: `<email>` / `<password>`. API token for server-side injection: `<token>`.
>
> Work through the ordered phases below. Do not skip a phase because it looks like scaffolding — phases 1 to 3 exist because skipping them produces hundreds of unreadable failures.
>
> Report failures and blockers. Do not report that normal things were normal.

---

## Phase 0 — Reconnaissance, before proposing anything

Verify each of these with a command and paste what it returned. Assume nothing.

| check | command |
|---|---|
| the device is really attached | `adb devices -l` |
| the app is installed | `adb shell pm list packages \| grep <package>` |
| the credentials actually authenticate | `curl -X POST <api>/auth/login -d '{...}'` |
| the injection token can write | one real `POST` to a resource, then delete it |
| an existing test harness runs at all | run one existing test end to end |

**Verify the credentials against the API before you touch the device.** A device run costs ten minutes; a curl costs one second. In the Givore campaign the given account turned out to be social-login only with no password at all — three device runs were burned discovering by hand what one curl said immediately.

**Find the token's real permission surface.** A token described as "write enabled" is not uniformly write enabled. Read the server's permission matrix if the backend repo is on the machine. Givore's token could author its own posts and comments but could never create, update, or ban a user — which silently rules out a whole class of injection scenarios you would otherwise plan for.

---

## Phase 1 — Make failures readable, before writing any test

**This is the phase everyone skips, and it invalidates everything downstream.**

On a real device a failing Flutter integration test reports:

```
'_pendingExceptionDetails != null': A test overrode FlutterError.onError but
either failed to return it to its original state…
```

That is the binding noticing *some* error occurred. It never says which. A campaign of 800 cases built on that harness produces 800 identical, useless failures.

Build a diagnostics layer first:

- An error recorder installed **before the app boots**, chaining to the previous handler rather than replacing it, that `print`s each error the moment it happens with a greppable marker. The cause is then already on stdout before the binding's opaque assertion fires.
- A note marker for what a case armed, chose, or created.
- A route marker — a wrong-screen failure is otherwise indistinguishable from a widget-never-built failure.
- An assertion wrapper that emits the route and the recorded errors before rethrowing.

Use `print`, not `debugPrint`: `debugPrint` truncates, and the truncated half is always the half you need.

**Then capture the device log for each case's window.** A native crash never reaches the Flutter output. Clear logcat, stream it to a file for the duration, and grep it into the case report. Trim it afterwards — raw logcat is megabytes of vendor noise.

---

## Phase 2 — Make gestures survive a real device

Widget-test gestures do not transfer to a phone. Three failures, all silent:

**The IME swallows taps.** `tester.enterText` raises the *real* system keyboard. Anything below the fold sits under the overlay and `tester.tap` is absorbed — no error, nothing submits, and the case dies thirty seconds later blaming something unrelated. The tell in the log is:

```
derived an Offset (…) that would not hit test on the specified widget
… RenderAbsorbPointer … RenderIgnorePointer … RenderAnimatedOpacity …
```

`FocusManager.primaryFocus?.unfocus()` alone does **not** fix it. Close the keyboard through the platform channel (`SystemChannels.textInput.invokeMethod('TextInput.hide')`), then pump past the retraction animation and the viewport-inset change.

**Write a `tapSafely` that checks reachability before tapping.** Hit-test the target's centre and confirm the result path contains the target's own render box. If it never becomes reachable, throw naming the obstruction — a named obstruction is a finding; a downstream assertion failure is a mystery.

**`pumpAndSettle`'s first argument is the frame interval, not a deadline.** The timeout is the third argument and defaults to ten minutes. `pumpAndSettle(Duration(seconds: 8))` pumps 8-second frames for up to ten minutes. A cold start hides this; a warm start that lands on a screen with a perpetual spinner never returns, and the case dies at the runner's kill with zero diagnostics. This bug sat in the Givore harness undetected across every existing test.

**Never `pumpAndSettle` after the app shell mounts.** Real apps have animations that never settle. Poll for a finder with bounded `pump` calls instead.

---

## Phase 3 — Build three injection planes

"Injection" means making the system genuinely misbehave, not mocking a repository. A mock proves the code you wrote does what you wrote; injection proves the user is not stranded.

**Transport.** Find the single choke point where every request leaves the app — one HTTP wrapper, one Dio instance — and add a library-level nullable seam there, consulted right where the response arrives. Null in every real build, so production cost is one null check.

Substitute the **response**, not the calling code. The app's real status mapping, real parsing, and real error UI then run.

Cover: 401, 403, 422, 429, 500, 503, socket exception, timeout, empty list, slow response, and **malformed JSON**. Make the body a raw `String`, not a `Map`, so a case can inject a truncated payload (`'{"data": [{"id": 1, "title": "unterminated'`). That is the case a mocked repository can never produce and the app is least likely to have handled.

Give each fault an optional `times` limit, so a case can prove the app *recovers* on retry rather than only that it fails correctly.

Record every request the seam observes. A case then asserts the app actually retried, or actually did **not** re-request after the user dismissed an error.

**Server.** Use the API token to create state that really exists: hostile strings rendered in the UI, a row deleted while its detail screen is open, a taxonomy entry renamed to 500 characters. Keep a `Hostile` fixture class — long text, RTL, emoji with ZWJ sequences, HTML-ish, zero-width joiners, many newlines, one unbreakable long word.

Check the server's own validation limits first. A 450-character title is rejected at 255 and your injection never reaches the UI.

**Device.** adb, from the host runner rather than inside the test: airplane mode, process kill, revoked runtime permission, rotation.

**Always disarm.** The seam is a global; a leftover fault poisons the next case in the same isolate. Register teardown inside the arming helper so a case cannot forget.

---

## Phase 4 — A ledger, not a checklist

The ledger is the **only** handoff between sessions. Everything else must be reconstructible from it.

**Append-only JSONL, last row per id wins.** A session killed mid-write truncates at most the tail line, which the reader skips. A rewrite-in-place file loses everything and cannot take two writers.

Row: `id`, `surface`, `kind` (happy/injection), `title`, `file`, `status`, `reason`, `run_at`, `evidence`.

Statuses: `planned`, `authored`, `pass`, `fail`, `blocked`, `flaky`. Terminal is `pass` / `fail` / `blocked`.

**`blocked` is not `fail`.** A case that cannot run for an environmental reason gets `blocked` plus the exact unblock action. Conflating the two makes the failure count meaningless.

**Put the stop criterion in the tool, not in a human's memory.** `status` should print, in words, whether the campaign is done: every surface has at least one happy and one injection case, and all are terminal.

**A failing case usually records the wrong reason.** An assertion failure leaves the tree undrained, teardown hangs, and the run is killed at the timeout — so the ledger says `timed out after 600s`, indistinguishable from a genuine hang. The real cause is in the case report. Tell the session to correct the reason.

---

## Phase 5 — Enumerate the backlog before running anything

The backlog is the denominator that gives "done" a meaning. Build it from the route table, not from intuition: read every route, open each screen, list every interactive element — buttons, fields, tile taps, swipes, pull-to-refresh, long-press, sheets, dialogs, tabs, toggles, pickers, pagination.

Cross-check against the release notes for the versions in scope. Everything they claim shipped must have a case.

**Every row states what it proves as an outcome the user sees.** "Tapping Save shows the new title in the feed", never "test the save button".

**Do not write an injection case for a fault a surface cannot experience.** A screen that issues no requests gets hostile content or a device-level fault, not a 500.

**Record what you deliberately excluded and why.** Placeholder routes with nothing to act on, near-identical redirects sharing one expression, options that do not exist in the UI. An unexplained gap looks like an oversight forever.

---

## Phase 6 — Survive the usage limit

A campaign of hundreds of device cases is far longer than one session's usage window. It cannot live inside a session.

**Shape:** a host-level loop fires periodically → starts a **fresh** headless session → it reads the ledger, takes N cases, runs them, records, commits, exits. A session killed by a limit costs at most that batch; the next firing continues from the ledger. Nothing else is carried between sessions.

**Small batches.** Four is a good number. A batch cut short still leaves every completed case recorded, and a small batch keeps each session's context lean.

**Back off on a rate limit.** A session that dies in under ~90 seconds hit the limit rather than finishing work. Write a cooldown timestamp and skip until it passes, instead of burning the allowance on failed starts every interval.

**Guard everything:** a lock file with a staleness reclaim, a device check that skips cleanly rather than reporting red, a branch check so an unattended commit can never land on a release branch, and a `PAUSED` file a human can touch.

**You will probably be blocked from installing this yourself.** Claude Code's permission classifier refuses both `crontab` edits and spawning `claude -p` from Bash — that is the guardrail against self-replication, and it should not be worked around. Build it, prove every part that can be proven, and hand the user two commands. Say plainly that the first unattended tick is unproven and what to watch.

---

## Phase 7 — Write the resume prompt, then attack it

The unattended session has no memory and no human. Its prompt is the whole product. Include: the repo and branch, the commands, the file layout, the harness reference, the environment facts, how to record a failure, and when to stop.

**Then run one batch through it with a worker and ask the worker what was missing.** In the Givore campaign that single exercise found five gaps, one of which was fatal:

**Nothing forbade weakening an assertion to turn a red into a green.** An unattended session meeting a real defect could soften the test and report green, and every number downstream becomes a lie. Give an explicit test:

| the test is wrong | the app is wrong |
|---|---|
| It asserts something the product never promised — a widget that does not exist, a count the seeded data does not guarantee. | It asserts the outcome a user is entitled to, and the app does not deliver it. |
| Fix the test. | Record `fail`, write the finding, move on. |

And: if you cannot tell, record `fail` and say so. A wrongly-filed defect costs someone five minutes; a softened assertion costs the campaign its meaning. **Never edit app source to make a test pass.**

The other four gaps, all worth pre-empting: the pause switch was undocumented; `flutter analyze` before a device run was not mandated (two seconds against ten minutes); tapping a link inside rendered markdown has no answer in a tap-the-box-centre helper — a link is a span, use `tapOnText`; and the per-case timeout override was never named.

**Check `.gitignore` before findings cite evidence.** A repo-wide `*.log` rule silently excluded every stdout and logcat file the findings pointed at. Add a negation for the campaign's run directory.

---

## Writing a case

1. Install the error recorder **first**, before booting.
2. Register the teardown drain immediately after boot, so an assertion failure still tears down cleanly.
3. Use the diagnostic assertion wrapper for load-bearing assertions.
4. Use the keyboard-safe tap and text helpers everywhere.
5. Assert painted geometry and real outcomes, not widget presence.

**An injection case proves the app degrades correctly**: it stays on the right screen, tells the user, and leaves the control usable. "It did not crash" is not a passing bar. Assert all three.

---

## Writing a finding

- What the user does, in three lines.
- What happens, quoting the recorded error or the assertion.
- What should happen.
- The exact file and line believed responsible, or "unknown".
- The evidence path.

**Reproduce host-side when you can.** A defect reproduced without the device is far cheaper for someone to confirm and fix.

**Scope the severity honestly.** The Givore markdown defect looked like an XSS hole and was content loss — Flutter paints text and cannot execute a script tag. Overstating it would have sent someone down the wrong path.

**Say whether the responsible widget is used elsewhere.** One shared markdown renderer meant the fix belonged below the screen that surfaced it.

---

## What to report to the user

Lead with what is unresolved. Never report that normal things were normal.

State plainly how many cases actually **ran** versus how many are **planned** — a backlog of 873 rows and 9 executed tests are different achievements, and conflating them is the easiest way to mislead.

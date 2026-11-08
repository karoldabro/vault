Spawned: [change-impact → root-cause-analyst, test-gap → quality-engineer, architecture-fit → system-architect, pattern-conformance → refactoring-expert, intent-trace → requirements-analyst]

PERSONA: change-impact
VERDICT: BLOCK
FINDINGS:
  - id: change-impact-1
    severity: MAJOR
    grounding: confirmed
    check: bin/report.sh:7 passes three arguments
    target: lib/format.sh:5
    issue: A clean caller reported as broken.
    recommendation: None.

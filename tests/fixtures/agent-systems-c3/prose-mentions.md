PERSONA: agent-systems
FINDINGS:
  - id: agent-systems-1
    severity: MAJOR
    grounding: confirmed
    check: config/support.php:144 sets judge_model.
    issue: The judge is unmeasured.
  - id: agent-systems-2
    severity: MINOR
    grounding: advisory
    check: none
    issue: Two more findings would say grounding: confirmed if they had evidence.
    recommendation: Note that grounding: confirmed needs a command.
PROPOSED_TESTS: []

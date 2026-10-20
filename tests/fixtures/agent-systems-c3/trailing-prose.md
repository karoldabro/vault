PERSONA: agent-systems
FINDINGS:
  - id: agent-systems-1
    severity: MAJOR
    grounding: confirmed
    check: none
config/support.php:144 sets judge_model, but this line is prose outside the block.
  - id: agent-systems-2
    severity: MAJOR
    grounding: confirmed
    check: none
  `grep -rn foo app` sits at the depth of the id line.
  - id: agent-systems-3
    severity: MAJOR
    grounding: confirmed
    check: app/Services/Ai/KnowledgeRetriever.php:68 takes the top rows.
    issue: The agent cannot abstain.
PROPOSED_TESTS: []

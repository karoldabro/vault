PERSONA: agent-systems
VERDICT: REQUEST_CHANGES
FINDINGS:
  - id: agent-systems-1
    severity: MAJOR
    grounding: confirmed
    check: "git show --stat 7a21f823 says the v5 pipeline scored 33% sendable against 56% for the v4 single call. ChatDraftService.php:71 calls singleShot(). SupportDraftPipeline.php:86-101 makes one call, no tools, no review."
    target: "plan § Task line 18, § Decisions line 103, C-7 line 56"
    issue: "The plan prescribes the draft-review-revise pipeline for live drafts, but its own replay rejected that rung and C-7 requires a review stage singleShot() never runs."
    recommendation: "Name singleShot() as the live drafter in § Task, line 103 and C-7, and keep run() as a replay arm only (skills/agent-shape/SKILL.md)."
  - id: agent-systems-2
    severity: MAJOR
    grounding: confirmed
    check: "grep -rnwiE 'tpr|tnr|kappa|human_label' app/ config/ returns nothing, exit 1. ReplayRunner.php:25 calibrates by compare(live, live). config/support.php:144 judge_model and config/ai.php:55 drafter are both claude-opus-5-5."
    target: "app/Prompts/SupportReplyJudge.php, config/support.php:144 and :193; plan C-2, C-3"
    issue: "The judge that gates C-2, C-3 and guidance promotion shares the drafter's model and was never measured against Carlos, matching 52% judged sendable versus 0 of 18 sent."
    recommendation: "Measure the judge against message_drafts SENT and REJECTED rows, report TPR and TNR with a config floor, and use a different model family (skills/agent-evals/SKILL.md)."
  - id: agent-systems-3
    severity: MAJOR
    grounding: confirmed
    check: "grep -rniE 'open.cod|axial|coded|failure (list|mode)|error analysis' over ~/vault/givore/plans/2026-10-19-1055-api-support-drafter-one-rulebook* and ADR-295, ADR-296 finds no coded-trace list."
    target: "plan § Success criteria C-2, C-3"
    issue: "The plan chose a judged sendable rate as its shipping metric before any human coded at least 50 real drafts into a counted failure list."
    recommendation: "Add a work item where Carlos codes at least 50 drafts, the 18 unsent production drafts first, and derive C-2 and C-3 from the top failure modes (skills/agent-evals/SKILL.md)."
  - id: agent-systems-4
    severity: MAJOR
    grounding: confirmed
    check: "In ~/workspace/dashboard.givore.com, grep -rn 'operator_note' app/ returns nothing, exit 1. DraftCard.vue:85-123 shows confidence, body and review notes only. SupportDraftPipeline.php:97 only appends breaches as notes."
    target: "app/Services/Support/SupportDraftPipeline.php:97; dashboard app/components/support/DraftCard.vue; plan line 35"
    issue: "Live LEAK and phrase-rule breaches land only in operator_note, which the dashboard never shows, so the accepted risk on plan line 35 has no working control."
    recommendation: "Store a draft with a LEAK or zero-limit PR breach as flagged, and show operator_note in DraftCard.vue before Send is enabled (skills/agent-output-validation/SKILL.md)."
  - id: agent-systems-5
    severity: MAJOR
    grounding: confirmed
    check: "SupportDraftPipeline.php:233 keeps only integer customer ids. ExampleLeakCheck.php:35-37 returns no breaches without ids. ExampleLeakCheck.php:76-88 checks name words, city and province only. The examples migration line 35 makes customer_id nullable."
    target: "app/Services/Support/ExampleLeakCheck.php:33-89; plan § Decisions line 109"
    issue: "The leak check skips examples with a null customer_id and ignores third-party names, streets and items inside example texts."
    recommendation: "Build leak tokens from each example's customer_text and reply_text, null-customer rows included, not only from the example customer's profile (skills/agent-output-validation/SKILL.md)."
  - id: agent-systems-6
    severity: MAJOR
    grounding: confirmed
    check: "grep -rniE 'https?:|url|link' over SupportDraftPipeline.php, PhraseRules.php, ExampleLeakCheck.php and SupportChatReplyDraft.php returns nothing, exit 1."
    target: "app/Services/Support/SupportDraftPipeline.php:219-228 codeBreaches()"
    issue: "No code check catches a URL or unmasked contact in a draft body, although customer text from this chat and from stored examples enters the prompt."
    recommendation: "Add a link and contact allowlist to codeBreaches() that fails closed outside givore.com (skills/agent-output-validation/SKILL.md)."
  - id: agent-systems-7
    severity: MAJOR
    grounding: confirmed
    check: "FullTextSearch.php:52-55 joins query words with OR. FullTextSearch.php:68-71 orders by ts_rank_cd with no minimum. KnowledgeRetriever.php:72-78 takes the top K with no floor. Minimum retrieval score: none."
    target: "app/Services/Ai/FullTextSearch.php:68-71, app/Services/Ai/KnowledgeRetriever.php:66-79, app/Services/Support/ReplyExampleRetriever.php:41-59"
    issue: "Retrieval returns any row sharing one word of three letters, with no rank floor and no abstain path."
    recommendation: "Add a configured minimum ts_rank_cd in FullTextSearch::search(), and escalate to Carlos without factual claims when nothing passes (skills/agent-knowledge-context/SKILL.md)."
  - id: agent-systems-8
    severity: MINOR
    grounding: confirmed
    check: "grep -rniE 'recall|hit_rate|ndcg|mrr' app tests finds only unrelated lines in RecordUserActivityJob.php:38 and ContentModeration.php:166. Plan W-40 verification is the end-to-end replay only."
    target: "plan W-40 line 186; app/Services/Ai/KnowledgeRetriever.php, app/Services/Support/ReplyExampleRetriever.php"
    issue: "W-40 replaced embeddings with full-text search over a 3.1 MB KB without measuring recall@k."
    recommendation: "Add a recall@k fixture of labelled query-to-row pairs from the replay cases and report it in support:drafts:replay (skills/agent-knowledge-context/SKILL.md)."
  - id: agent-systems-9
    severity: MAJOR
    grounding: confirmed
    check: "config/support.php:143 sets min_replay_cases 20. config/support.php:189-191 sets calibration_runs 3 and min_margin 3. grep for rollback, revert or power in the learner files returns nothing. Plan line 93 shows 71 cases are noise-bound."
    target: "app/Services/Support/SupportGuidanceLearner.php; app/Console/Commands/SupportLearnCommand.php"
    issue: "The weekly learner promotes guidance into every live draft on 20 cases, with no power analysis, no online confirmation and no rollback command."
    recommendation: "Size min_replay_cases by power analysis, confirm a promotion against Carlos's sent rate, and add a rollback to the previous live row (skills/agent-self-improvement/SKILL.md)."
  - id: agent-systems-10
    severity: MAJOR
    grounding: confirmed
    check: "grep -rn 'private/support\\|replay-2026' app/Services/AccountDeletion/ returns nothing, exit 1. SupportDraftsReplayCommand.php:332 reads the replay file. Plan line 92 counts real names in 61 of 71 gold replies."
    target: "app/Services/AccountDeletion/UserCleanupService.php:218-240; storage/app/private/support/*.json; plan line 27"
    issue: "The replay files hold real customer conversations, the plan copies them between worktrees, and user erasure never reaches them."
    recommendation: "Give each replay file a retention rule and make UserCleanupService drop an erased customer's cases from them (skills/agent-runtime-ops/SKILL.md)."
  - id: agent-systems-11
    severity: MINOR
    grounding: confirmed
    check: "grep -rnE 'input_tokens|output_tokens|usage|cost' SupportTextCompletion.php ChatDraftRecorder.php returns nothing, exit 1. ChatDraftRecorder.php:33-42 stores no token or cost field."
    target: "app/Services/Support/ChatDraftRecorder.php:33-42; app/Services/Support/SupportDraftPipeline.php:287-297"
    issue: "No draft, judge or learner call records tokens or cost, and no daily spend budget exists."
    recommendation: "Log Prism token usage and cost in the pipeline line and replay runs, and add a daily token budget to config/support.php (skills/agent-runtime-ops/SKILL.md)."
  - id: agent-systems-12
    severity: MINOR
    grounding: confirmed
    check: "SupportChatReplyDraft.php:218-219 puts each example's customer_text into the live prompt. Plan line 108 says reply text only stops third-party customer text."
    target: "app/Prompts/SupportChatReplyDraft.php:206-222 examples()"
    issue: "The live EXAMPLES block carries other customers' raw messages, so a stored message can inject instructions into another customer's draft behind only a fence."
    recommendation: "Render reply_text only in the EXAMPLES block, or keep it and add test agent-systems-t1 (skills/agent-trust-boundaries/SKILL.md)."
PROPOSED_TESTS:
  - id: agent-systems-t1
    kind: feature
    target: tests/Feature/Services/Support/ChatDraftServiceTest.php
    intent: "A Prism fake obeying an injected link and foreign name from a stored example must produce a flagged draft, never a clean pending_review draft."
    priority: must
  - id: agent-systems-t2
    kind: feature
    target: tests/Feature/Services/Support/ExampleLeakCheckTest.php
    intent: "An example with a null customer_id whose reply names Marta must still yield a LEAK line when the draft repeats Marta."
    priority: must
  - id: agent-systems-t3
    kind: feature
    target: tests/Feature/Console/SupportDraftsReplayCommandTest.php
    intent: "With drafts labelled by Carlos's action and a faked judge, the replay command reports TPR and TNR and exits 1 below the floor."
    priority: should
NEW_SINCE_LAST_ROUND: []

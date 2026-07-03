---
from: {{from_project}}
to: {{to}}          # a project slug, or `pm` for a decision that changes the generic plan / a contract
asks: {{one-line question}}
opened: {{date}}
---

# {{asks}}

## Context
<!-- What's blocked, the specific field / endpoint / decision, and why it can't be answered locally. -->

## Answer
<!-- The answering project / PM writes here, then renames the file: OPEN_→<to> → ANSWERED_<answerer>. -->

<!-- State lives in the FILENAME, not this file:
     THREAD_<n>_OPEN_→<to>.md          open, waiting on <to>
     THREAD_<n>_ANSWERED_<answerer>.md  answered, waiting for the asker to consume
     THREAD_<n>_RESOLVED.md            asker consumed the answer -->

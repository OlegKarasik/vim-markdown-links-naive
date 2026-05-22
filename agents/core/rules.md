# Rules

These rules govern AI-agent workflow in this repository and define
cross-repository plugin API conventions where explicitly stated.

1. DO NOT create or edit files outside of repository.
2. DO NOT redirect output from commands into files outside of repository.
3. DO NOT add or take dependencies on other plugins.
4. DO NOT introduce fallback behavior when a canonical interaction path is defined (for example, if popup UI is used, do not add a list/inputlist fallback).
5. Every public user-facing Ex command must expose a `<Plug>(...)` mapping target.
6. Plugin startup mapping registration must not override an existing `<Plug>(...)` mapping with the same left-hand side.
7. In tests only, any single time-based wait/check interval must not exceed 90 seconds.
8. Every update to plugin functionality must be reflected to its wiki.
9. These global core rules override conflicting local core rules for AI-agent workflow.
10. Global asynchronous rules in `global-async-rules.txt` (umbrella root) are mandatory and override conflicting local async rules.

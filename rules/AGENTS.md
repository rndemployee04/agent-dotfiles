# Engineering Agent Guidelines & Operating Protocol

## 1. Core Operating Principles
- **Minimal Diffs**: Touch only files required for the scoped task. Never reformat, clean up, or refactor adjacent or unrelated files.
- **Destructive Action Gate**: Never execute destructive git actions (`git push -f`, `git reset --hard`, `git clean`), drop database tables, or overwrite `.env` files without explicit confirmation.
- **Explain Intent Before Large Edits**: State a 2–3 bullet summary of intent before editing multi-file architectures.
- **Local-First Grounding**: Always inspect local files, tests, and codebase context first. Never query external services (GitHub, Context7) for local bugs or local tasks unless explicitly requested.

## 2. Architecture & Code Conventions
- **Thin Controllers, Rich Domain**: Controllers strictly handle HTTP transport (validation, authorization, and dispatch). All business logic belongs in Action classes, Domain Services, or Models.
- **Strict Typing & Dependency Injection**: Use explicit typing and constructor dependency injection. Avoid untyped escape hatches (`any`, `mixed`) unless interfacing with dynamic third-party payloads.
- **Idiomatic Patterns**: Favor clean, maintainable, self-documenting code over clever hacks.

## 3. The 4-Stage Subagent Swarm Protocol
To keep context windows clean and prevent collisions, tasks must follow this role division:
- **`@planner`**: Explores the codebase (read-only), interviews requirements in rounds (via `/grill-me`), designs deep modules (`/codebase-design`), and splits work into atomic tickets (`/to-tickets`). Never output a static plan without grilling first. **Never writes code.**
- **`@implementer`**: Executes the blueprint in an isolated Git worktree (`git worktree add`). Adheres to MVC standards and applies `/tdd` or `/implement-spec`.
- **`@tester`**: Runs unit/feature test suites and acts as a context firewall for terminal logs. Uses `/diagnosing-bugs` on failure and reports exact stack traces back to `@implementer`. **Never edits production code.**
- **`@reviewer`**: Senior auditor. Performs dual-axis code reviews (`/code-review`), checking architectural conformance, security vulnerabilities, and project guidelines before PR/merge.

> **Command Disambiguation**: In CLI sessions, Antigravity's native `/plan` command generates a static artifact. To trigger the interactive requirements interview and vertical ticket breakdown, use `/grill-me <task>` or delegate directly to `@planner`.

## 4. Definition of "Done" & Quality Gates
A task is considered complete **only** when all of the following gates pass:
1. **Accompanying Tests**: New features and bugfixes must include corresponding unit/feature tests.
2. **Zero Regressions**: Existing and new test suites pass with zero failures.
3. **Static Analysis & Linting**: Linters and typechecks pass with zero new warnings.
4. **Clean Handoff**: If the session is closing, use `/handoff` to save active state for future resumption.

## 5. Git & State Hygiene
- Never commit broken builds or failing tests.
- Isolate parallel agent tasks using lightweight Git worktrees to prevent file collisions and lockfile corruption.

## 6. GitHub Tool & MCP Guardrails
When interacting with GitHub via tools or MCP servers:
- **Draft PRs Only**: Any pull request created by an agent MUST be opened as a Draft (`draft: true`). Never mark a PR as ready for review or attempt to merge it.
- **Never Auto-Merge or Delete**: The agent is strictly prohibited from merging pull requests, deleting branches, or deleting repositories.
- **Issue Etiquette**: The agent may read issues and post exploratory comments or diff plans. Never close an issue without explicit human confirmation.
- **Zero Secret Exposure**: Never post tokens, environment variables, credentials, or `.env` contents in GitHub comments, PR bodies, or commit messages.

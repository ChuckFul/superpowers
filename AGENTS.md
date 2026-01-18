# Superpowers Agents

Superpowers is a skill-driven workflow plugin for coding agents (Claude Code, Codex, OpenCode). This repo houses skills, plugin manifests, and shared tooling.

## Mission

Maintain and evolve the Superpowers skill library and plugin integrations with clarity and correctness. Keep skills composable, token-efficient, and aligned with documented behavior across Claude Code, Codex, and OpenCode.

## Process

1. Read this file, `README.md`, and the relevant platform docs (`docs/README.codex.md`, `docs/README.opencode.md`, `docs/testing.md`) before changing behavior.
2. Identify the affected area (skills, shared library, plugin/CLI). Prefer minimal, scoped changes.
3. For skills, edit `skills/<skill>/SKILL.md` with valid frontmatter and trigger guidance; use `skills/writing-skills/SKILL.md` when adding or restructuring skills.
4. Update installation docs and `RELEASE-NOTES.md` for user-visible changes; keep CLI/plugin behavior and docs consistent.
5. Run the relevant tests under `tests/` (or note why not). For plugin behavior, prefer the platform-specific suites in `tests/opencode/` or `tests/claude-code/`.
6. Update Session Handoff and commit your changes.

## Tracking and Session Handoff (mandatory)

- Use `update_plan` (or a lightweight checklist) for active work.
- Overwrite the Session Handoff section at the end of each session.
- Keep handoff entries concise and actionable.

### Session Handoff (rolling, mandatory)

- Goal: Capture intended Superpowers behavior in a Codex-facing analysis note.
- Changes: Added a codex analysis summary note; updated Session Handoff.
- Files: AGENTS.md, docs/codex-analysis/superpowers-intended-behavior.md
- Risks/Notes: Documentation-only; no behavior changes.
- Next: If needed, link the analysis note from README or expand with diagrams.
- Tests: Not run (doc-only change).
- Commit: Superpowers: add codex analysis notes

## Documentation Update Directives (mandatory)

All agents must keep these documents current when making changes:

- `README.md` - project overview, installation entrypoints, and workflow summary.
- `RELEASE-NOTES.md` - user-visible changes and version history.
- `docs/README.codex.md` - Codex install and usage guide.
- `docs/README.opencode.md` - OpenCode install and usage guide.
- `docs/testing.md` - test strategy and instructions.
- `.codex/INSTALL.md` - Codex installation snippet used by setup workflows.
- `.opencode/INSTALL.md` - OpenCode installation snippet used by setup workflows.

Update architecture docs when introducing new patterns or refactors. If manual testing is required, document it in a dedicated `MANUAL_TESTING_*.md` file and reference it in the handoff.

## Commit Directives (mandatory)

- Commit all changes you made before ending the session unless the user explicitly says not to.
- Stage and commit everything you created, modified, or deleted, including new/untracked files and deletions.
- Do not stop work or refuse to continue due to untracked/modified files; add and commit your own changes and leave unrelated files unstaged.
- Include `AGENTS.md` updates in the same commit as the code changes they describe.
- Use a commit message prefix of `Superpowers:` followed by a short summary.
- If a commit cannot be made, state the reason in Session Handoff.

## Purpose and Superpowers Approach

Superpowers delivers a composable skill system and plugin integrations so agents can follow structured workflows. Keep skills clear, minimal, and accurate; avoid duplicating long docs inside skills. Favor shared behavior via `lib/skills-core.js` and keep platform-specific adapters aligned.

Example key files:
- `skills/` (per-skill instructions in `SKILL.md`)
- `lib/skills-core.js` (shared skill parsing and discovery)
- `.opencode/plugin/superpowers.js` (OpenCode plugin)
- `.codex/superpowers-codex` (Codex CLI)
- `commands/` (Claude Code command definitions)

## Quick Start Workflow

1. Read `README.md` and the platform docs relevant to the change.
2. Find the affected skill or integration code and make the minimal change.
3. Update documentation and release notes if behavior changed.
4. Run the relevant tests (or document why they were not run) and update Session Handoff.

## Superpowers Reference Map

### Primary Documentation

- `README.md` - overview and workflow.
- `docs/README.codex.md` - Codex setup and CLI behavior.
- `docs/README.opencode.md` - OpenCode setup and plugin behavior.
- `docs/testing.md` - test strategy and execution.
- `RELEASE-NOTES.md` - release history.

### Secondary References

- `.codex/INSTALL.md` - Codex install snippet for automation.
- `.opencode/INSTALL.md` - OpenCode install snippet for automation.
- `.codex/superpowers-bootstrap.md` - bootstrap content loaded by Codex.
- `.claude-plugin/plugin.json` - Claude Code plugin manifest.
- `.claude-plugin/marketplace.json` - marketplace metadata.
- `agents/code-reviewer.md` - review agent template.

### Code Organization

- `skills/` - skill folders with `SKILL.md`.
- `lib/skills-core.js` - shared core logic.
- `.codex/` - Codex bootstrap and CLI.
- `.opencode/plugin/` - OpenCode plugin entry.
- `commands/` - Claude Code command definitions.
- `tests/` - integration and behavior tests.
- `docs/` - platform guides and testing docs.

## Mandatory Guardrails (do not skip)

### Skill Frontmatter and Triggers

Every skill must keep valid frontmatter and a clear trigger description.

```markdown
---
name: skill-name
description: Use when [condition] - [what it does]
---
```

Do not rename skill folders without updating references and docs.

### Cross-Platform Consistency

If a skill changes behavior or tooling assumptions, update the Codex and OpenCode docs and confirm mappings still match the plugin implementations.

### Testing and Verification

Run or update the relevant tests under `tests/` when behavior changes. If tests are not run, record the reason in Session Handoff.

## JavaScript and Plugin Essentials for Superpowers

- `lib/skills-core.js` is ES module code shared by Codex and OpenCode integrations.
- `.codex/superpowers-codex` is a Node CLI; keep the shebang and CLI output stable.
- `.opencode/plugin/superpowers.js` provides `use_skill` and `find_skills` tools and handles bootstrap injection on session events.

## Troubleshooting Checklist

- If skills are not found, verify skill folder structure and `SKILL.md` frontmatter.
- If bootstrap or tools fail, check the platform-specific plugin/CLI files and install docs.
- If tests fail, consult `docs/testing.md` and the relevant `tests/` subdirectory.

## Search Tips for the Reference Corpus

```bash
# From the repo root
rg --files -g "*.md"
rg -n "SKILL.md|superpowers-codex|use_skill|find_skills" .
rg -n "bootstrap|frontmatter|resolveSkillPath" lib .codex .opencode
```

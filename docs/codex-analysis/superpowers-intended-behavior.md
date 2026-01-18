# Superpowers Intended Behavior (Codex Analysis)

This note summarizes how Superpowers is intended to operate based on repo docs
and the core tooling.

## Core Intent
- Provide a skill-driven workflow system for coding agents with mandatory
  process discipline (brainstorming -> plan -> TDD -> review -> finish).
- Keep skills composable, token-efficient, and aligned across Claude Code,
  Codex, and OpenCode.
- Prefer minimal, scoped changes; update docs and tests when behavior changes.

## Skill-First Contract
- Before any action or response, check for relevant skills and load them.
- If a skill applies, you must use it; this includes clarifying questions.
- Skills define the "how" even when the user defines the "what".

## Canonical Workflow Chain
- Brainstorming: refine requirements and design, validate in short sections, and
  save a design doc in docs/plans.
- Using git worktrees: isolate work, verify ignored worktree directory, run
  setup, and confirm tests pass before implementation.
- Writing plans: produce bite-sized TDD steps with exact file paths and commands.
- Executing plans: run tasks in batches with checkpoints or dispatch subagents
  per task in the same session.
- TDD: always write a failing test first, watch it fail, then implement minimal
  code and re-run tests.
- Request review after each task/batch, fix findings, then finish the branch
  with explicit merge/PR/keep/discard options.

## Platform Integrations
- Claude Code: plugin + commands that map directly to skills, enforced via
  slash commands (brainstorm, write-plan, execute-plan).
- Codex: Node CLI that bootstraps skills, lists skills, and loads skills by
  name; auto-loads using-superpowers during bootstrap.
- OpenCode: plugin injects bootstrap at session creation and after compaction,
  plus tools for use_skill and find_skills.

## Skill Discovery and Precedence
- Skills are defined by SKILL.md with YAML frontmatter (name, description).
- Shared core logic in lib/skills-core.js parses frontmatter, lists skills, and
  resolves skill paths.
- Precedence for OpenCode: project skills > personal skills > superpowers skills.
- Codex: personal skills override superpowers when names match.

## Testing Expectations
- Integration tests run real sessions and validate behavior via transcript
  parsing.
- Platform-specific suites live under tests/claude-code and tests/opencode.

## Key Files
- README.md
- AGENTS.md
- docs/README.codex.md
- docs/README.opencode.md
- docs/testing.md
- .codex/superpowers-codex
- .codex/superpowers-bootstrap.md
- .opencode/plugin/superpowers.js
- lib/skills-core.js

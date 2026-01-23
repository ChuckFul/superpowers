# Superpowers Research Document

## Executive Summary

Superpowers is a **complete software development workflow system** for coding agents, built on composable "skills" and mandatory processes. It transforms agents from ad-hoc code generators into disciplined engineers who follow proven methodologies.

**Why it's imperative:** Without Superpowers, agents rationalize their way around best practices, skip testing, guess instead of investigating, and claim work is complete without verification. Superpowers enforces discipline through explicit rules, rationalization prevention, and mandatory workflows.

---

## Part 1: Philosophy and Core Principles

### The Problem Superpowers Solves

Coding agents have a fundamental flaw: they want to appear helpful and productive. This leads to:

1. **Jumping into code immediately** without understanding requirements
2. **Skipping tests** because "it's simple" or "I'll test after"
3. **Making random fixes** instead of investigating root causes
4. **Claiming completion** without verification
5. **Rationalizing around best practices** with plausible-sounding excuses

### The Superpowers Solution

Superpowers addresses these by:

1. **Mandatory skill invocation** - Before ANY task, check if a skill applies
2. **Explicit rationalization prevention** - Tables of common excuses with rebuttals
3. **Iron Laws** - Non-negotiable rules like "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST"
4. **Process over guessing** - Systematic approaches with defined phases
5. **Evidence before claims** - Verification required before completion claims

### Core Philosophy

| Principle | Description |
|-----------|-------------|
| **Test-Driven Development** | Write tests first, always. Watch them fail. |
| **Systematic over ad-hoc** | Process beats guessing every time |
| **Complexity reduction** | Simplicity as primary goal (YAGNI, DRY) |
| **Evidence over claims** | Verify before declaring success |
| **Violating the letter = violating the spirit** | No clever workarounds |

---

## Part 2: The Complete Workflow

Superpowers defines a **complete development lifecycle**:

### Phase 1: Brainstorming
**Skill:** `brainstorming`

- Agent does NOT jump into code
- Asks questions one at a time to understand requirements
- Proposes 2-3 approaches with trade-offs
- Presents design in 200-300 word sections for validation
- Writes design document to `docs/plans/YYYY-MM-DD-<topic>-design.md`

### Phase 2: Worktree Setup
**Skill:** `using-git-worktrees`

- Creates isolated workspace on new branch
- Verifies directory is gitignored
- Runs project setup (npm install, cargo build, etc.)
- Verifies clean test baseline before starting

### Phase 3: Planning
**Skill:** `writing-plans`

- Creates detailed implementation plan
- Each task is bite-sized (2-5 minutes)
- Includes exact file paths, complete code, verification commands
- Plans assume engineer has "zero context and questionable taste"
- Emphasizes TDD, YAGNI, DRY, frequent commits

### Phase 4: Execution
**Skills:** `subagent-driven-development` OR `executing-plans`

Two options:
- **Subagent-driven:** Fresh subagent per task with two-stage review
- **Executing-plans:** Batch execution with human checkpoints

### Phase 5: Review
**Skills:** `requesting-code-review`, `receiving-code-review`

- Code review after each task (mandatory in subagent workflow)
- Two-stage: spec compliance first, then code quality
- Critical issues block progress

### Phase 6: Completion
**Skill:** `finishing-a-development-branch`

- Verify tests pass
- Present structured options (merge/PR/keep/discard)
- Clean up worktree

---

## Part 3: Skills Anatomy

### What is a Skill?

A skill is a **reference guide** containing:
- Proven workflows and processes
- Mandatory rules and constraints
- Rationalization prevention
- Checklists and verification steps

### Skill Structure

```
skills/
  skill-name/
    SKILL.md              # Main content (required)
    supporting-file.*     # Only if needed (prompts, tools)
```

### SKILL.md Format

```markdown
---
name: skill-name
description: Use when [triggering conditions] - triggers only, NO workflow summary
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
- Specific symptoms/situations
- When NOT to use

## The Iron Law (for discipline skills)
Non-negotiable rule in code block

## The Process
Flowchart or steps

## Common Rationalizations
| Excuse | Reality |
Table of excuses with rebuttals

## Red Flags - STOP
List of warning signs

## Quick Reference
Table for scanning
```

### Critical CSO (Claude Search Optimization) Rule

**Description = ONLY triggering conditions, NEVER workflow summary**

Testing revealed that when descriptions summarize the workflow, Claude follows the short description instead of reading the full skill. This caused massive failures where two-stage review became one review, etc.

```yaml
# BAD - Claude follows this instead of reading skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# GOOD - Just triggers, forces Claude to read skill
description: Use when executing implementation plans with independent tasks in the current session
```

### Skill Types

| Type | Purpose | Example |
|------|---------|---------|
| **Discipline** | Enforce rules/requirements | TDD, verification-before-completion |
| **Technique** | How-to guides | condition-based-waiting, root-cause-tracing |
| **Pattern** | Mental models | reducing-complexity |
| **Reference** | Documentation | API docs, command references |

---

## Part 4: Slash Commands

### What is a Slash Command?

User-invocable shortcuts that redirect to skills. Simple wrappers.

### Structure

```markdown
---
description: Brief description
disable-model-invocation: true  # User-only, Claude cannot invoke
---

Invoke the superpowers:skill-name skill and follow it exactly as presented to you
```

### Available Commands

| Command | Skill |
|---------|-------|
| `/superpowers:brainstorm` | `superpowers:brainstorming` |
| `/superpowers:write-plan` | `superpowers:writing-plans` |
| `/superpowers:execute-plan` | `superpowers:executing-plans` |

### Key Design Decision

Commands have `disable-model-invocation: true` - Claude cannot invoke them via Skill tool. This prevents confusion where Claude would invoke a command that just redirects to a skill anyway.

---

## Part 5: Agents vs Task Agents

### Defined Agents

Located in `agents/` directory with full system prompts:

```markdown
---
name: code-reviewer
description: Use when a major project step has been completed...
model: inherit
---

You are a Senior Code Reviewer with expertise in...
[Full personality and instructions]
```

**Characteristics:**
- Full persona and expertise defined
- Comprehensive instructions
- Reusable across contexts
- Registered in plugin's agent system

### Task Agents (Generic with Prompts)

Invoked via Task tool with specific prompts:

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description
    [FULL TEXT - don't make agent read files]

    ## Context
    [Where this fits, dependencies]
    ...
```

**Characteristics:**
- Generic agent type (general-purpose)
- All context provided in prompt
- One-off, task-specific
- Controller provides everything needed

### Key Differences

| Aspect | Defined Agent | Task Agent |
|--------|---------------|------------|
| **Definition** | Persistent in `agents/` | Ad-hoc via prompt |
| **Context** | Has expertise/persona | Gets context from controller |
| **Reuse** | Reusable across projects | Single-use |
| **Complexity** | Full system prompt | Just task instructions |

### The Hybrid: Reviewer Agents

Superpowers uses defined agents (code-reviewer) with task-specific prompts (spec-reviewer-prompt.md, code-quality-reviewer-prompt.md). The defined agent provides expertise; the prompt provides task context.

---

## Part 6: Sub-Agent Orchestration

### The Subagent-Driven Development Pattern

**Core principle:** Fresh subagent per task + two-stage review = high quality, fast iteration

### Flow

```
Controller reads plan
  ↓
Extract ALL tasks with full text upfront
  ↓
For each task:
  ├─ Dispatch Implementer subagent
  │    └─ Can ask questions (before AND during)
  │    └─ Implements, tests, commits
  │    └─ Self-reviews before reporting
  ├─ Dispatch Spec Reviewer subagent
  │    └─ Verifies implementation matches spec
  │    └─ If issues → Implementer fixes → re-review
  ├─ Dispatch Code Quality Reviewer subagent
  │    └─ Reviews for quality (only after spec passes)
  │    └─ If issues → Implementer fixes → re-review
  └─ Mark task complete
  ↓
Final code review of entire implementation
  ↓
Finish development branch
```

### Prompt Templates

**Implementer (`implementer-prompt.md`):**
- Full task text (don't make them read files)
- Context about where task fits
- Permission to ask questions
- Self-review checklist before reporting

**Spec Reviewer (`spec-reviewer-prompt.md`):**
- What was requested
- What implementer claims
- CRITICAL: Do not trust the report - verify by reading code
- Check for missing requirements AND extra work

**Code Quality Reviewer (`code-quality-reviewer-prompt.md`):**
- Uses code-reviewer agent template
- Only runs after spec compliance passes

### Critical Rules

1. **Never skip reviews** - both stages mandatory
2. **Never proceed with unfixed issues** - fix and re-review
3. **Never dispatch parallel implementers** - conflicts
4. **Never make subagent read plan file** - provide full text
5. **Spec compliance BEFORE code quality** - wrong order fails

### Parallel Agents

**Skill:** `dispatching-parallel-agents`

For independent problems (different test files, different subsystems):
- Dispatch one agent per problem domain
- Let them work concurrently
- Review and integrate results

**NOT for:** Related failures, shared state, exploratory debugging

---

## Part 7: Template Prompts Design

### What Makes an Effective Prompt

1. **Self-contained** - All context needed, no file reading required
2. **Focused** - One clear goal
3. **Structured** - Sections for description, context, instructions, output format
4. **Skeptical** - Don't trust previous reports (for reviewers)

### Template Structure

```markdown
You are [role description]

## [Task/Requirements Section]
[FULL TEXT - paste, don't reference]

## Context
[Where this fits, dependencies, background]

## Before You Begin (for implementers)
[Permission to ask questions]

## Your Job
[Specific steps to follow]

## [Rules/Constraints]
[What to do, what NOT to do]

## Report Format
[Exact output structure expected]
```

### Key Pattern: Controller Provides Everything

The controller (orchestrating agent) does the work of:
- Reading the plan file ONCE
- Extracting ALL tasks with full text
- Providing context for each task
- Subagents receive everything they need

This prevents subagents from:
- Reading files and getting confused
- Missing context
- Interpreting requirements differently

---

## Part 8: Plugin and Marketplace Architecture

### Plugin Structure

```
superpowers/
├── .claude-plugin/
│   └── marketplace.json     # Plugin metadata
├── skills/                   # Skill library
├── commands/                 # Slash commands
├── agents/                   # Defined agents
├── lib/
│   └── skills-core.js       # Shared code
├── .codex/                   # Codex integration
│   ├── superpowers-codex    # CLI tool
│   └── superpowers-bootstrap.md
└── .opencode/               # OpenCode integration
    └── plugin/
        └── superpowers.js   # Plugin entry
```

### Marketplace JSON

```json
{
  "name": "superpowers-dev",
  "description": "Development marketplace...",
  "owner": { "name": "...", "email": "..." },
  "plugins": [
    {
      "name": "superpowers",
      "description": "Core skills library...",
      "version": "4.0.3",
      "source": "./"
    }
  ]
}
```

### Cross-Platform Support

| Platform | Integration |
|----------|-------------|
| **Claude Code** | Native plugin via marketplace |
| **Codex** | CLI tool + bootstrap document |
| **OpenCode** | JavaScript plugin with custom tools |

### Tool Mapping

Skills reference Claude Code tools. Other platforms map:

| Claude Code | Codex | OpenCode |
|-------------|-------|----------|
| `TodoWrite` | `update_plan` | `update_plan` |
| `Task` (subagents) | Manual (no subagents) | `@mention` |
| `Skill` | CLI command | `use_skill` tool |
| `Read/Write/Edit` | Native equivalents | Native equivalents |

### Skill Resolution Priority

1. **Project skills** (`.opencode/skills/` or project-local)
2. **Personal skills** (`~/.claude/skills/`, `~/.codex/skills/`)
3. **Superpowers skills** (plugin-provided)

Personal skills override superpowers when names match.

---

## Part 9: The using-superpowers Skill (Bootstrap)

This is the **most critical skill** - it establishes the discipline.

### The Rule

**Invoke relevant or requested skills BEFORE any response or action.**

Even a 1% chance a skill might apply = invoke it to check.

### Mandatory First Steps

```
User message received
  ↓
Might any skill apply?
  ↓
If yes (even 1%): Invoke Skill tool
  ↓
Announce: "Using [skill] to [purpose]"
  ↓
Has checklist? → Create TodoWrite todos
  ↓
Follow skill exactly
```

### Red Flags (Rationalizations)

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I know what that means" | Knowing concept ≠ using skill. Invoke it. |

### Skill Priority

When multiple skills apply:
1. **Process skills first** (brainstorming, debugging)
2. **Implementation skills second** (frontend-design, mcp-builder)

"Let's build X" → brainstorming first, then implementation skills.

---

## Part 10: Why Superpowers is Imperative

### Without Superpowers

Agents will:
- Jump into code without understanding requirements
- Write tests after (which proves nothing)
- Make random fixes instead of investigating
- Claim "should work now" without verification
- Overbuild with unnecessary features
- Skip reviews because "it's simple"
- Rationalize around every best practice

### With Superpowers

Agents:
- Ask questions first, understand deeply
- Follow TDD (test-first, watch fail, minimal code)
- Investigate systematically before fixing
- Verify with evidence before claiming
- Apply YAGNI ruthlessly
- Review after every task
- Follow the skill exactly, no rationalization

### The Evidence

From the codebase:
- 24 documented failure memories of claiming completion without verification
- Hours wasted on false completion → redirect → rework
- "I don't believe you" - trust broken with human partner

### The Enforcement Mechanism

1. **Iron Laws** - Non-negotiable rules
2. **Rationalization tables** - Pre-empt excuses
3. **Red flags** - Warning signs to stop
4. **Verification requirements** - Evidence before claims
5. **Two-stage review** - Spec compliance then quality

---

## Summary: Key Takeaways for Toolset Design

1. **Skills are the backbone** - Composable, proven workflows
2. **Mandatory, not optional** - "If skill applies, you MUST use it"
3. **Rationalization prevention is critical** - Agents will find loopholes
4. **Process skills before implementation skills** - Brainstorm before build
5. **Controller provides context to subagents** - Don't make them read files
6. **Two-stage review** - Spec compliance then quality
7. **Evidence before claims** - Verification is non-negotiable
8. **Description = triggers only** - Never summarize workflow in description
9. **Cross-platform design** - Tool mapping for different environments
10. **Skill priority system** - Project > personal > superpowers

When designing toolsets, **Superpowers must be the backbone**. Every tool should:
- Be invocable as a skill
- Have mandatory workflows where appropriate
- Include rationalization prevention
- Require verification before completion
- Integrate with the Superpowers ecosystem

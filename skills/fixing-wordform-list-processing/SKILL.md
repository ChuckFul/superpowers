---
name: fixing-wordform-list-processing
description: Use when diagnosing or fixing WordForm OpenXML list-processing parity failures, especially when list scenarios or artifacts show clause expansion, separator, or hidden storage mismatches.
---

# Fixing WordForm List Processing

## Overview
List processing is the last major OpenXML parity gap. This skill enforces an artifact-first, test-gated workflow so fixes are traceable, minimal, and repeatable.

**REQUIRED BACKGROUND:** You MUST understand superpowers:systematic-debugging and superpowers:test-driven-development.

**REQUIRED SUB-SKILLS (WordForm repo):**
- `simple-test-runner`
- `field-code-extractor`

**REQUIRED DOCS (WordForm repo):**
- `docs/list-processing-research/planning/LIST_PROCESSING_AGENT_SYSTEM.md`
- `docs/list-processing-research/README.md`
- `docs/list-processing-research/planning/OPENXML_COMPLETION_PLAN.md`
- `docs/list-processing-research/list-processing-issues-2026-01-20.md`

## Primary Path: Phase 4 Scenarios 19-24 (MANDATORY)

These scenarios are the primary path forward because they generate the richest artifacts for diagnosing list behavior. Start here before any other list tests.

- `19-list-1-item`
- `20-list-2-items`
- `21-list-3-items`
- `22-list-5-items`
- `23-list-ditto-clause2`
- `24-list-ditto-clause3`

Run each with the simple runner:

```powershell
pwsh .claude/skills/simple-test-runner/scripts/Run-SimpleOpenXmlTest.ps1 -ScenarioFolder 19-list-1-item
```

## Workflow (Gated, One Issue at a Time)

Follow the List Processing Agent Execution System. Do not skip gates.

1. **Intake**
   - Pick ONE issue from the ledger.
   - Define the minimal scenario (usually 19-24) and success criteria.
2. **Repro + Evidence**
   - Run the scenario with `simple-test-runner`.
   - Review artifacts (`field-codes.tsv`, `document-order.tsv`, `text.txt`) and diff outputs.
3. **Hypothesis**
   - Identify the smallest code path that explains the artifact diff.
   - Write a single-change plan (no batching).
4. **Implement**
   - Apply the minimal change.
   - Add Serilog instrumentation if the failure is not observable in artifacts.
5. **Validate**
   - Re-run the same scenario and its nearest neighbors.
   - Compare against the VBA baseline artifacts.
6. **Document + Close**
   - Update the issue entry with root cause, fix, and tests.
   - Add notes to `docs/list-processing-research/testing/` when new evidence is created.

## Mandatory Observability (Serilog, Verbose)

Verbose structured logging is required for list-processing work.

**Log properties (minimum):** `ListId`, `ItemIndex`, `Layer`, `Step`

**Example:**
```csharp
_logger.LogDebug(
    "List processing step {Step} for list {ListId} item {ItemIndex} layer {Layer}",
    step,
    listId,
    itemIndex,
    layer);
```

Log ALL exceptions with `_logger.LogError(ex, "...")` before rethrowing.

## Anti-Thrash Rules (Non-Negotiable)

- One issue per change set.
- One hypothesis per iteration.
- No test = no merge (or explicitly record why not).
- If a change does not improve the diff, revert or re-scope before another fix.

## Common Mistakes

- Skipping scenarios 19-24 and running broad suites first.
- Using manual Word inspection instead of artifacts to drive hypotheses.
- Adding multiple fixes at once.
- Logging without structured properties or at too-low verbosity.

## Common Rationalizations (from baseline test)

| Excuse | Reality |
| --- | --- |
| "Run the list/phase parity tests and bucket failures." | Start with 19-24 to get artifact-rich, minimal repros before widening scope. |
| "Pick one failing scenario only; inspect its template." | Pick from the issue ledger and rely on artifacts first; template inspection is secondary. |
| "Trace the pipeline at key joints." | Trace every list step with verbose, structured Serilog to correlate with artifact diffs. |
| "Rerun the single test, then the full phase." | Rerun the scenario and its neighbors; expand only after artifacts stabilize. |

## Red Flags - STOP

- "I'll just run the full list phase first."
- "This fix is obvious; no need to diff artifacts."
- "I'll combine a couple of fixes while I'm here."
- "Logging can wait until after the fix."

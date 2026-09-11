# Agent Token Efficiency Plan

This repository should guide agents toward narrow, verifiable work instead of repeated broad exploration.

## Goals

- Reduce time and token use on repeated Ruptura Temporal tasks.
- Keep project identity, Game Base parity, and Godot validation intact.
- Make the workflow portable through GitHub between machines.
- Avoid weakening the completion rule for real code, scene, resource, test, or project changes.

## Implementation

1. Version a repository skill at `.agents/skills/ruptura-token-efficient-workflow/SKILL.md`.
2. Reference that skill from `AGENTS.md` before the domain-specific Godot skills.
3. Keep the skill narrowly focused on context budgeting, edit scope, validation choice, and concise reporting.
4. Use `.gitignore` exceptions so this skill is tracked while local agent files remain ignored.

## Operating Model

Agents should start with a five-command discovery pass:

- `git status --short`;
- targeted `rg` search for the exact symbol or behavior;
- focused line-window reads from affected scripts;
- required skill reads only;
- nearest focused test or validator lookup.

After that pass, the agent should pick a concrete implementation path or explain the one missing piece of context. Broad scans are reserved for unclear ownership, shared systems, or validation failures with no local stack trace.

## Validation Policy

- Docs and skill-only changes: skill structure check plus `git diff --check`.
- Narrow script changes: parse touched scripts and run the nearest focused test.
- Gameplay, VFX, UI, AI, collision, or scene changes: focused test plus affected scene or flow smoke.
- Shared systems, release, export, project settings, addons, or unclear blast radius: deep Godot validation.

The validator can still produce known warnings. Agents must distinguish warnings from actionable errors and report that boundary precisely.

## Acceptance Criteria

- New agents see the token-efficient workflow from `AGENTS.md`.
- The skill is not hidden by `.gitignore`.
- The plan is documented in `docs/agent_token_efficiency_plan.md`.
- Future final reports stay compact: files changed, commands run, pass/fail, and unexercised paths.

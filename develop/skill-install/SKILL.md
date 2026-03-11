---
name: skill-install
description: Install Codex skills into /home/fxy/github-Xyxy1722/Agent-skills by functional category, create symlinks in ~/.codex/skills, and commit each installed skill safely without staging unrelated changes.
origin: ECC
---

# Skill Install

Install and register Codex skills in a repeatable way.

## When to Activate

- installing one or more new skills for Codex
- syncing a skill from another repository into `Agent-skills`
- creating `~/.codex/skills` symlinks for installed skills
- committing installed skill paths while preserving unrelated git changes

## Required Workflow

1. Identify the source skill directory and the destination category in `/home/fxy/github-Xyxy1722/Agent-skills`.
2. Reuse an existing category when possible.
3. If no destination category matches, ask the user before creating a new directory.
4. Install the skill into the category directory.
5. Create or refresh `~/.codex/skills/<skill-name>` as a symlink to the installed skill.
6. Stage only the installed skill path.
7. Commit with the exact message `install skill of <skill-name>`.

## Category Selection

Prefer these existing directories first:

- `develop/` for coding, backend, API, testing, review, refactor, and tooling skills
- `trading/` for market, strategy, and execution skills
- `usage/` for end-user tool usage and productivity skills

## Git Rules

- Never include unrelated modified or untracked files in the same commit.
- If the target repository is dirty, use path-specific `git add` commands.
- Report commit SHAs and push status after installation.

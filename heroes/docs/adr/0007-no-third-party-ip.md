# 0007 No third-party IP

## Status

Accepted, 2026-11-11

## Context

The repository is public.
Git history is never rewritten, so anything committed stays.
A downstream theme pack may use names this repository must not hold.

## Decision

No third-party intellectual property in this repository, ever.
This covers files, commits, branch names and PR text.
Use only original, generic names.
If a name might belong to an existing franchise, pick another.
This repository never names a downstream theme pack.
Checks run locally through git hooks.
There are no GitHub Actions workflows and no `.github` folder.

## Consequences

* The public origin name is "Gifted".
* Agents and contributors choose a different name when unsure.
* A downstream pack keeps its own word list and hooks outside this repository.
* A leak cannot be undone, so the hooks run before commit and push.

## Evidence

Untested: the hooks are not written yet.
The rule is a policy and has no prototype.

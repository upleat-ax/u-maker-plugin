# Scenario Decision — Auto-detection Heuristics

> How `/u-prepare` picks scenario A / B1 / B2 automatically, and how it phrases the override prompt when the choice is ambiguous. PBGD Plan.Prepare, v4.0.

## 1. Signals

`/u-prepare` inspects the project root (parent of `.u-maker/`) for these signals:

| Signal | Check |
|--------|-------|
| **Source manifest present** | Any of: `package.json`, `pom.xml`, `build.gradle`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `composer.json`, `mix.exs`, `Package.swift` |
| **Source directory present** | Any of: `src/`, `app/`, `lib/`, `pkg/`, `cmd/` containing at least one source file |
| **Git repo with commits** | `.git/` present and `git log --oneline | head -1` produces a line |
| **Dropzone has content** | `data/dropzone/**` contains ≥ 1 file (excluding hidden and link descriptors) |
| **Dropzone has links only** | `data/dropzone/links/*.{figma-link,url,code-link}` exists but no other files |

## 2. Decision matrix

| Source manifest | Source dir | Dropzone content | Auto-selected scenario | Action |
|:---:|:---:|:---:|---|---|
| ✗ | ✗ | ✗ | **A (wait)** | Prompt user to add files/links, wait |
| ✗ | ✗ | ✓ | **A** | Proceed directly to `/u-analyze` |
| ✓ | ✓ | ✗ | **ambiguous** | Prompt B1 vs B2 (see §3) |
| ✓ | ✓ | ✓ | **B1** | Proceed to `/u-analyze` (dropzone is richer than code alone) |
| ✗ | ✓ | ✗ | **B2 (soft)** | Prompt "Reverse-engineer now?" default-yes |
| ✗ | ✓ | ✓ | **B1** | Proceed to `/u-analyze` |
| ✓ | ✗ | * | **ambiguous** | Print warning ("manifest without source?") and prompt A/B1/B2 |

A `--scenario {A|B1|B2}` command-line flag always overrides auto-detection.

## 3. Override prompt wording

When ambiguous:

```
Existing source detected at {absolute-path}.
  Files found: package.json, src/ (42 files), README.md
  Dropzone:    (empty)

How would you like to prepare?
  (1) B1 — I'll drop supplementary docs/Figma links into data/dropzone/ first.
  (2) B2 — Reverse-engineer the code into a digest now.
  (3) Both — B1 first, then augment with /u-reverse afterwards.
  (4) A  — Ignore existing code; plan from scratch.

Choice [1-4]:
```

The prompt lists concrete files found, so the user can verify the heuristic detected the right thing.

## 4. Skip detection with `--auto`

With `--auto`, the decision matrix is applied strictly — ambiguous rows resolve as follows:

| Ambiguous case | `--auto` default |
|----------------|------------------|
| source + source-dir + no-dropzone | B2 |
| manifest + no source-dir | A |

This allows unattended runs (e.g., from `/u-loop`) to proceed without user input. Human-in-the-loop runs should omit `--auto`.

## 5. Logging the decision

The selected scenario is written to `.state/loop-state.json` under `prepare.scenario` so subsequent skills and reports can reference it.

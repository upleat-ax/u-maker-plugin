# HTML Template — data schema + fill procedure

The asset `assets/roadmap-template.html` is the **reference roadmap engine**, generalized. It is the interactive Gantt style the user anchored on: vanilla CSS, **light mode only**, width switcher (1440/1680/1920), draggable/contenteditable, localStorage autosave. This skill **overrides** the general u-maker HTML rules (no Tailwind, no dark-mode toggle, no Mermaid) — match this template's style exactly. (Font Awesome **is** loaded in the template `<head>` via CDN, so `fa-*` icon classes are available for UI chrome; glyphs inherit `currentColor` and fit the light-mode palette.)

## Fill procedure (critical)

1. **Copy** the asset to the output path — do not regenerate it:
   ```bash
   cp skills/u-reports-roadmap/assets/roadmap-template.html \
      .u-maker/reports/<date>/roadmap-<slug>-<deadline>.html
   ```
2. **Edit ONLY** two regions of the copy:
   - The JS **`ROADMAP DATA` block** (`CONFIG` + `UPCOMING` + `DEFAULT_TRACKS` + `DEFAULT_PHASES` + `DEFAULT_DEADLINES` + `DEFAULT_MILESTONES` + `DEFAULT_DETAILS`).
   - The HTML **`<!-- GEN:* -->` markers** in `<head>`/`<body>` (title, hero, subtitle, headline, dday-hint, tracks-hint, framing, footer-path).
3. **Never touch the engine** (everything under `ENGINE — reusable. Do not edit below this line.`). The drag/snap/render logic is tuned; regenerating it drifts behavior and wastes tokens.

## Calendar anchoring — the #1 failure mode

There are **no hardcoded dates in the engine**. Set them once in `CONFIG`:

```js
const CONFIG = {
  lsKey: 'roadmap-<slug>-v1',  // unique per report
  startDate: '2026-06-01',      // W1 start (the plan-window "now")
  deadline:  '2026-08-11'       // hard deadline → D-day + FINAL column
};
```

`buildTimeline()` derives all 12 column labels/date-ranges and the D-day target from these two values — it splits the span into 11 working segments (W1..W10 + FINAL) so the deadline always lands in the FINAL column (weekly buckets when span≈10–11wk, bi-weekly when longer). `UPCOMING` is the only date list to fill by hand (future checkpoints as `new Date(year, month-1, day)`); keep it consistent with `DEFAULT_MILESTONES`. Verify after filling: the FINAL column shows the real deadline and the snapshot D-day is correct.

## Data schema

```js
// Track = a Gantt row (app or feature-area). color → CSS var --track-{color}.
{ id:'appA', color:'blue1', title:'앱A · 핵심', subtitle:'한 줄 설명' }

// Phase = a bar. from/to are week ids (PRE | W1..W10 | FINAL).
{ from:'W1', to:'W4', label:'API 배선', meta:'모듈화 (TBD)',
  release:{kind:'done|normal|fair|launch', label:'v1'},  // optional ◆ marker
  muted:true }                                            // optional 빗금(지속) bar

// Deadline = vertical pin. at=week id, within=0..1 fraction inside bucket.
{ id:'d-final', label:'통합 마감', at:'FINAL', within:0.143, kind:'soft|launch|hard',
  appliesTo:['appA'] }   // optional: track-scoped (omit = whole-board overlay)

// Milestone = timeline dot.
{ date:'7/31', label:'기능 프리즈', cls:''|'done'|'launch'|'fair' }

// Detail = per-track text (inline HTML). notes = risk output.
{ positioning:'<p>…</p>', highlights:'<ul><li>…</li></ul>', notes:'<p>…</p>' }
```

`DEFAULT_PHASES` / `DEFAULT_DETAILS` are objects keyed by `track.id` — every track id must appear in both.

## Color palette

Assign one **hue family per app/product group**; use `common` (grey) for cross-cutting tracks:

| Family | slots | suggested use |
|---|---|---|
| blue | `blue1..blue4` | product/app group 1 |
| green | `green1..green4` | product/app group 2 |
| amber | `amber1..amber4` | product/app group 3 |
| rose / violet | `rose1 rose2 violet1 violet2` | extra groups |
| common | `common` | BE-dependency / SSoT / QA |

To add more slots, extend the `:root` `--track-*` vars in the asset CSS (the one place CSS edits are allowed).

## Grid horizon

12 columns are fixed (PRE + W1..W10 + FINAL = 11 working segments); bucket size = span/11, so the deadline lands in FINAL. For spans longer than ~11 weeks the buckets become bi-weekly automatically — label phases by bucket id, not raw weeks. Changing the column **count** would require editing `repeat(12,…)` / `calc(100%/12)` / the `91.66%` fair-shade in CSS and the `12`/`11` literals in the engine; avoid unless necessary.

## Output location + index + sidecar

- Output: `.u-maker/reports/<date>/roadmap-<slug>-<deadline>.html` (dated subfolder, matching the reference path convention). Create the folder if absent.
- Update `.u-maker/reports/index.html` and the root `.u-maker/index.html` hub (per `skills/u-engine/references/html-engine.md`).
- Write a sidecar `.u-maker/reports/<date>/roadmap-<slug>-<deadline>.data.json` capturing the **generated** state (tracks/phases/deadlines/milestones/details/config) so `--rerender` can rebuild without re-analysis. Note: this captures only the generated seed — once the user drags/edits in the browser, those live edits persist in **localStorage only** (one-way; no write-back to the HTML or sidecar). The footer says to share the HTML file itself.

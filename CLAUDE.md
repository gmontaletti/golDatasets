# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Repository nature

This is a **data repository**, not a software project. There is no git
history, no build system, no test suite, and no package manifest. It
collects:

- CSV datasets extracted from the periodic monitoring reports of Italy’s
  **Programma GOL** (Garanzia Occupabilità Lavoratori) published by
  ANPAL, MLPS, and INAPP.
- Two Python extraction scripts that produce the CSVs from the upstream
  PDFs.

The source PDFs themselves are not stored here — they live in a separate
`rapporti/timeline_gol/` tree referenced by the long-format dataset’s
`file` column. Treat the CSVs as the canonical artifact.

## Directory layout

| Path | Origin | Granularity |
|----|----|----|
| `dataset_long/` | 27 GOL reports (ANPAL/MLPS/INAPP) | 11 thematic long CSVs (`gol_A1_long.csv` … `gol_L_long.csv`), one row per (file, caption, anchor, col_index) cell |
| `INAPP GOL/csv_long/` | 12 INAPP Focus GOL reports | Long + wide CSVs for tables 1.1, 1.2, 2.1, 2.2/3.1, plus the unified `tab_long_completo.csv` and `diagnostica.csv` |
| `INAPP GOL/focus_gol_17/` | single PDF (Focus GOL 17/2025, data 31/12/2025) | All 19 tables of that single report, one CSV + one `.txt` layout dump each, indexed by `_indice_tabelle.csv` |
| `percorsi/` | INAPP reports | Alternative long/wide pair for tables 1.1, 1.2, 2.1, 2.2 (different schema from `INAPP GOL/csv_long/`) |
| `cob/` | INPS “Allegato IV-Trimestre” XLSX files | Regional avviamenti/cessazioni flows in long form, one row per (regione, anno, trimestre, flusso) |

`dataset_long/README.md` is the authoritative schema document for the
GOL thematic long format. `INAPP GOL/verifica_coerenza.md` documents the
validation checks behind the INAPP extractor and one known PDF-side
discrepancy (30/06/2024 report, 6 cells, \< 0.1%).

## Running the two extractors

Both scripts live under `INAPP GOL/` and are standalone — they do not
share a virtualenv definition. Install the listed dependencies locally
before running.

**`estrai_tavole_inapp_gol.py`** — produces `INAPP GOL/csv_long/*` from
the multi-report INAPP Focus GOL corpus.

``` bash
python3 "INAPP GOL/estrai_tavole_inapp_gol.py" \
    --input-dir /path/to/PDFs \
    --output-dir "INAPP GOL/csv_long"
```

Backends: `pdftotext` (Poppler) as primary, `pdfplumber` as Python
fallback. The `--pattern` flag overrides the default filename glob —
necessary because the PDFs are often named by UUID rather than the
canonical `INAPP_FocusGOL_*.pdf`.

**`estrai_tavole_focus_gol_17.py`** — produces
`INAPP GOL/focus_gol_17/*` from the single Focus GOL 17/2025 PDF.
Requires `tabula-py` (stream mode) and `pdftotext`. Each target table is
hard-coded by page range in the `TARGETS` list at the top of the file;
editing that list is the way to add or correct a table.

The 11 `gol_*_long.csv` files in `dataset_long/` are produced by a
script that lives outside this repo (`outputs/extract_long.py`,
referenced in `dataset_long/README.md` line 72) requiring `pdfplumber`
and the original PDFs in their archive location.

## Cross-cutting schema conventions

These hold across every long-format CSV in the repo and must be
respected when joining, normalising, or extending datasets.

**Regional anchors are canonicalised to 22 labels.** The list is
`Abruzzo, Basilicata, P.A. Bolzano, Calabria, Campania, Emilia-Romagna, Friuli-Venezia Giulia, Lazio, Liguria, Lombardia, Marche, Molise, Piemonte, Puglia, Sardegna, Sicilia, Toscana, P.A. Trento, Umbria, Valle d'Aosta, Veneto, Totale`
(or `Italia`). Aggregate aliases — `Nord-Ovest`, `Nord-Est`, `Nord`,
`Centro`, `Sud`, `Sud e Isole`, `Mezzogiorno`, `Isole`, `Italia` — are
the only acceptable non-regional anchors. `FVG`, lettering-spaced
variants (`Ba s i l i ca ta`), and apostrophe variants (`d'`, `D'`,
`U+2019`) all map to the canonical form. The INAPP extractor does this
normalisation in `REGIONI_PATTERN`.

**Three series breaks in the long history.** When building time series,
treat these as discontinuities:

1.  *Presi in carico → individui coinvolti* (2025 INAPP format): unit
    changes from event to person; 2025 tables often expose both side by
    side.
2.  *Regione di presa in carico → regione di ultima presa in carico*
    (2025 captions): reassignment rule changes for multi-region
    individuals; check Italia-total vs. regional sum.
3.  *Four → five GOL pathways* with the introduction of *Ricollocazione
    collettiva* in 2025: changes column count of tables A1, F, H, I —
    `col_index` is not comparable across the 2025 boundary for these
    themes.

**`unit_guess` is heuristic.** Token contains a comma → `decimal` (or
`percent` if in \[-1, 1000\]); no comma and no dot, or dot-as-thousands
→ `count`; `-` or `n.d.` → `missing` with null `valore_num`. Always
cross-check via `header_above` before computing on `valore_num`.

**Quality flags.** `ok` (97.3% of `dataset_long/`) means the row came
from a well-structured regional table with a recognised anchor.
`best_effort` (6.8%) covers themes I/J/K/L with variable structure —
verify the `col_index → variable` mapping per `caption_num` before use.
`no_data_extracted` (7 rows) marks captions detected with no extractable
data row (typically raster tables).

## Working in this repo

- **Italian is the canonical language for column names, anchors, table
  titles, and section comments.** When writing R scripts use the
  section-header syntax `# 1. nome sezione -----` (from the user’s
  global instructions). Avoid pure `####` separator lines.
- **Use neutral technical language in documents.** Match the tone of
  `dataset_long/README.md` and `INAPP GOL/verifica_coerenza.md` — no
  emphatic language.
- **PDF filename conventions are not stable.** The INAPP extractor must
  tolerate UUID-named PDFs. Do not introduce code that hard-codes the
  `INAPP_FocusGOL_*.pdf` pattern.
- **`.claude/` and other dotfiles must not be moved during cleanup
  operations** (from global instructions).
- **The `r-btw` MCP is for R library documentation only**, not for
  general web lookups or REST APIs.

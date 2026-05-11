# golDatasets 0.4.0

## Quality assessment

* `gol_quality_classify(n_anchor, pct_na_valore, n_header_variants,
  n_col_index)`: classificatore basato su 4 metriche, produce 5 tier di
  severita': `ok`, `review`, `rescan_low`, `rescan_high`,
  `rescan_critical`.
* `gol_storico_quality(data = NULL)`: applica il classificatore al
  dataset storico e produce una tabella diagnostica per
  `(file, tema, caption_num)`.

## Rebuild di gol_storico_regionale

* **INAPP A1/1.2**: le 10-11 estrazioni rotte (1-3 anchor invece di 21)
  in `dataset_long/gol_A1_long.csv` sono sostituite automaticamente con
  la versione decodificata di `INAPP GOL/csv_long/tab_1_2_long.csv`.
  Risultato: tutti i file INAPP per quella tavola hanno ora 22 anchor
  e 10 col_index (5 percorsi × {abs, pc}).
* Aggiunta colonna `rescan_severity` con valori `ok`, `rescan_low`,
  `replaced_from_inapp_csv_long` per tracciare la provenienza.
* Le 3 estrazioni ANPAL 2022 e 3 ANPAL/ALTRO F/2.1 con 19-20 anchor
  sono marcate `rescan_low` e raccolte in
  `gol_rescan_recommendations` come future-work per re-estrazione
  manuale.

## Dataset esposti

* `gol_rescan_recommendations`: snapshot delle anomalie residue dopo
  la build, una riga per `(file, tema, caption_num)` da ri-estrarre.

## Documentazione

* Vignette `merge-gol-cob` estesa con sezione "Qualità delle
  estrazioni storiche".

# golDatasets 0.3.0

## Funzioni

* `gol_extract_series()`: pivota `gol_inapp_mensile` in serie pronte per
  `plot_timeline()`. Inferenza automatica della tavola dalla `variabile`,
  supporto multi-regione (aggiunge la colonna `regione` quando le
  etichette sono piu' di una), filtro opzionale su `percorso` e
  `unita_misura`.

## Documentazione

* Vignette `merge-gol-cob` estesa con tre nuovi grafici GOL: confronto
  multi-regione di `occupati_totale`, decomposizione per percorso (tav
  1.2) di Emilia-Romagna, confronto prestazioni LEP (tav 2.1) di
  Lombardia.

# golDatasets 0.2.0

## Funzioni

* `plot_timeline()`: visualizza una timeline regionale con annotazione
  opzionale delle rotture di metodo. Usa palette CVD-safe Okabe-Ito di
  default per il confronto multi-serie.
* `cob_compute_indicators()`: a partire da `cob_regionale_trimestrale`
  produce un wide-table con 11 indicatori derivati per
  `(regione, anno, trimestre)`: saldi netti, indici di rotazione
  (rapporti / lavoratori) e variazioni YoY (lag 4 trimestri).

## Dataset esposti

* `gol_method_ruptures`: 3 eventi di discontinuita' metodologica nei dati
  GOL al passaggio del 2025 (cambio unita', regola regionale, 4 -> 5
  percorsi). Pensato per essere passato al parametro `ruptures` di
  `plot_timeline()`.

## Dipendenze

* Aggiunti `ggplot2` e `rlang` a Imports.

## Documentazione

* Vignette `merge-gol-cob` estesa con esempi grafici (rotture annotate,
  multi-regione, indicatori COB).

# golDatasets 0.1.0

Prima release del package.

## Dataset esposti

* `gol_inapp_mensile`: 10.922 osservazioni, 12 date di riferimento da
  2024-06-30 a 2025-12-31, 4 tavole INAPP Focus GOL (1.1, 1.2, 2.1, 2.2/3.1).
* `gol_storico_regionale`: 20.493 osservazioni, 25 date da 2022-09-09 a
  2025-12-31, 4 temi GOL con schema stabile (A1, B, F, H), `quality_flag = "ok"`
  e anchor regionale canonico.
* `cob_regionale_trimestrale`: 1.470 osservazioni, 35 trimestri da 2017-Q1
  a 2025-Q3, 21 regioni canoniche, flussi `avviamenti` e `cessazioni`.

## Funzioni esposte

* `build_gol_datasets()`: rigenera i tre dataset dai CSV grezzi
  (`dataset_long/`, `INAPP GOL/csv_long/`, `cob/`) e li salva come `.rda`
  in `data/`.

## Documentazione

* Vignette `merge-gol-cob`: esempio di merge cross-dataset tra serie
  INAPP GOL e baseline COB INPS sulla chiave regionale canonica.
* Sito pkgdown configurato (`_pkgdown.yml`) con deploy via GitHub Action
  (`.github/workflows/pkgdown.yaml`) verso GitHub Pages.

## Convenzioni

* Etichette regionali armonizzate alle 22 canoniche definite in
  `dataset_long/README.md`.
* Nomi regionali COB normalizzati: `Bolzano/Bolzen` → `P.A. Bolzano`,
  `Trento` → `P.A. Trento`, `Emilia Romagna` → `Emilia-Romagna`,
  `Friuli Venezia Giulia` → `Friuli-Venezia Giulia`,
  `Valle d'Aosta/Vallée d'Aoste` → `Valle d'Aosta`.
* Aggregati `N.D.` e `Totale` esclusi dai dati COB.

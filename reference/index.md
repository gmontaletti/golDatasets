# Package index

## Costruzione dei dataset

Funzioni per rigenerare i .rda dai CSV grezzi.

- [`build_gol_datasets()`](https://gmontaletti.github.io/golDatasets/reference/build_gol_datasets.md)
  :

  Costruisce i tre dataset canonici GOL e li scrive in `data/`

## Indicatori e visualizzazione

Trasformazione dei flussi COB in indicatori derivati e timeline
regionali con annotazione delle rotture metodologiche.

- [`cob_compute_indicators()`](https://gmontaletti.github.io/golDatasets/reference/cob_compute_indicators.md)
  : Calcola indicatori derivati dai flussi COB
- [`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md)
  : Disegna una timeline con eventuali annotazioni di rotture di metodo

## Dataset

Dataset esposti dal package, accessibili con
[`data()`](https://rdrr.io/r/utils/data.html) o direttamente come
oggetti.

- [`gol_inapp_mensile`](https://gmontaletti.github.io/golDatasets/reference/gol_inapp_mensile.md)
  : Serie INAPP Focus GOL mensile (2024-06 -\> 2025-12)
- [`gol_storico_regionale`](https://gmontaletti.github.io/golDatasets/reference/gol_storico_regionale.md)
  : Storico GOL regionale 2022-2025 (temi A1, B, F, H)
- [`cob_regionale_trimestrale`](https://gmontaletti.github.io/golDatasets/reference/cob_regionale_trimestrale.md)
  : Comunicazioni Obbligatorie regionali trimestrali (2017-Q1 -\>
  2025-Q3)
- [`gol_method_ruptures`](https://gmontaletti.github.io/golDatasets/reference/gol_method_ruptures.md)
  : Rotture di metodo nella serie GOL

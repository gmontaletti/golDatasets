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

## Convenzioni

* Etichette regionali armonizzate alle 22 canoniche definite in
  `dataset_long/README.md`.
* Nomi regionali COB normalizzati: `Bolzano/Bolzen` → `P.A. Bolzano`,
  `Trento` → `P.A. Trento`, `Emilia Romagna` → `Emilia-Romagna`,
  `Friuli Venezia Giulia` → `Friuli-Venezia Giulia`,
  `Valle d'Aosta/Vallée d'Aoste` → `Valle d'Aosta`.
* Aggregati `N.D.` e `Totale` esclusi dai dati COB.

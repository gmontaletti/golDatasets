# Package index

## Costruzione dei dataset

Funzioni per rigenerare i .rda dai CSV grezzi.

- [`build_gol_datasets()`](https://gmontaletti.github.io/golDatasets/reference/build_gol_datasets.md)
  :

  Costruisce i tre dataset canonici GOL e li scrive in `data/`

## Estrazione e indicatori

Helper per pivotare i dataset long in serie pronte per la
visualizzazione.

- [`gol_extract_series()`](https://gmontaletti.github.io/golDatasets/reference/gol_extract_series.md)
  :

  Estrai una serie temporale pronta per plot da `gol_inapp_mensile`

- [`gol_storia_volumi_series()`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_volumi_series.md)
  : Estrae una serie di volumi (presi in carico) per plot_timeline

- [`gol_storia_caratteristiche_series()`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_caratteristiche_series.md)
  : Estrae una serie di caratteristiche dei beneficiari

- [`gol_storia_esiti_series()`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_esiti_series.md)
  : Estrae una serie di esiti (occupazionali, LEP, politiche)

- [`gol_decode_storico()`](https://gmontaletti.github.io/golDatasets/reference/gol_decode_storico.md)
  : Applica il decoder semantico a gol_storico_regionale

- [`cob_compute_indicators()`](https://gmontaletti.github.io/golDatasets/reference/cob_compute_indicators.md)
  : Calcola indicatori derivati dai flussi COB

- [`build_inapp_focus_long()`](https://gmontaletti.github.io/golDatasets/reference/build_inapp_focus_long.md)
  : Costruisce il long format delle tabelle INAPP focus_gol_all

- [`dedup_storia()`](https://gmontaletti.github.io/golDatasets/reference/dedup_storia.md)
  : Deduplica un dataset di storia lunga GOL

## Visualizzazione

Timeline regionali con annotazione delle rotture metodologiche.

- [`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md)
  : Disegna una timeline con eventuali annotazioni di rotture di metodo

## Qualita’ delle estrazioni

Valutazione delle estrazioni PDF e identificazione delle tavole da
ri-estrarre.

- [`gol_storico_quality()`](https://gmontaletti.github.io/golDatasets/reference/gol_storico_quality.md)
  :

  Calcola le metriche di qualita' per `gol_storico_regionale`

- [`gol_quality_classify()`](https://gmontaletti.github.io/golDatasets/reference/gol_quality_classify.md)
  : Classifica la qualita' di un'estrazione GOL storica

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

- [`gol_rescan_recommendations`](https://gmontaletti.github.io/golDatasets/reference/gol_rescan_recommendations.md)
  : Raccomandazioni di rescanning per le estrazioni storiche GOL

- [`storico_decoder`](https://gmontaletti.github.io/golDatasets/reference/storico_decoder.md)
  :

  Decoder semantico per `gol_storico_regionale`

- [`gol_storia_volumi`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_volumi.md)
  : Storia lunga GOL: presi in carico 2022-2025

- [`gol_storia_caratteristiche`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_caratteristiche.md)
  : Storia lunga GOL: caratteristiche dei beneficiari 2022-2025

- [`gol_storia_esiti`](https://gmontaletti.github.io/golDatasets/reference/gol_storia_esiti.md)
  : Storia lunga GOL: esiti 2022-2025

# Rotture di metodo nella serie GOL

Tre eventi documentati di discontinuita' metodologica nei dati GOL,
tutti collocati al passaggio dal formato pre-2025 (ANPAL/MLPS) al
formato INAPP Focus GOL del 2025. Pensato per essere passato come
parametro `ruptures` a
[`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md).

## Usage

``` r
gol_method_ruptures
```

## Format

Un `data.table` con 3 righe e le colonne:

- data:

  `IDate`, data convenzionale della rottura (2025-01-01).

- evento:

  Descrizione sintetica dell'evento.

- scope:

  Ambito interessato (quali temi / quali colonne).

- riferimento:

  Documento di riferimento.

## Source

`dataset_long/README.md`, sezione "Cambiamenti di definizione lungo la
serie".

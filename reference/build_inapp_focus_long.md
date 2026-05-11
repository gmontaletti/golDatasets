# Costruisce il long format delle tabelle INAPP focus_gol_all

Cicla sui CSV in `INAPP GOL/focus_gol_all/<report_id>/` invocando i
mapper specifici per ciascuna tabella supportata. Le tabelle non coperte
da un mapper sono ignorate silenziosamente.

## Usage

``` r
build_inapp_focus_long(root = "INAPP GOL/focus_gol_all")
```

## Arguments

- root:

  Cartella radice `INAPP GOL/focus_gol_all/`. Se `NULL`, usa il default
  rispetto alla cwd.

## Value

Una lista con due `data.table`: `caratteristiche` (da 1.5) e `esiti` (da
2.3). Se nessun mapper produce output, lista con data.table vuoti.

## Details

Coperte: 1.5 (patto servizio per target), 2.3 (formazione competenze
digitali per dimensione).

Non coperte (future work): 1.3, 1.4, 1.6, 1.7.

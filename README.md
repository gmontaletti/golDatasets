# golDatasets

<!-- badges: start -->
<!-- badges: end -->

`golDatasets` raccoglie tre dataset regionali canonici relativi al **Programma GOL** (Garanzia Occupabilità Lavoratori), estratti dalle Note di monitoraggio ANPAL / MLPS / INAPP e dagli Allegati statistici INPS, in formato `data.table` long pronto per l'analisi.

## Dataset

| Dataset | Periodo | Granularità | Fonte |
|---|---|---|---|
| `gol_inapp_mensile` | 2024-06 → 2025-12 (12 report) | report × tavola × regione × variabile × percorso | INAPP Focus GOL |
| `gol_storico_regionale` | 2022-09 → 2025-12 (27 PDF) | tema × file × data × regione × col_index | ANPAL / MLPS / INAPP, temi A1, B, F, H |
| `cob_regionale_trimestrale` | 2017-Q1 → 2025-Q3 (35 trimestri) | regione × anno × trimestre × flusso | INPS "Allegato IV - Trimestre" |

I nomi regionali sono armonizzati alle 22 etichette canoniche (21 regioni / PPAA + `Totale`/`Italia`).

## Installazione

```r
# install.packages("remotes")
remotes::install_github("gmontaletti/golDatasets")
```

## Esempio

```r
library(golDatasets)
library(data.table)

# Serie mensile INAPP: presi in carico per anno e regione
data("gol_inapp_mensile")
pic_2025 <- gol_inapp_mensile[tavola == 1.1 &
                              variabile == "individui" &
                              dimensione == "regione"]
pic_2025[, .(media_mensile = mean(valore)), by = etichetta][order(-media_mensile)]

# Storico A1 (presi in carico × percorso) dal 2022
data("gol_storico_regionale")
gol_storico_regionale[tema == "A1" & anchor == "Emilia-Romagna",
                      .(data_riferimento, col_index, valore_num, unit_guess)]

# COB INPS: avviamenti trimestrali
data("cob_regionale_trimestrale")
cob_regionale_trimestrale[flusso == "avviamenti" & regione == "Lombardia",
                          .(anno, trimestre, rapporti, lavoratori)]
```

## Rigenerare i dataset dai CSV grezzi

I file `.rda` in `data/` sono prodotti dalla funzione `build_gol_datasets()` a partire dai CSV in `dataset_long/`, `INAPP GOL/csv_long/` e `cob/`. Per rigenerarli (richiede di avere i CSV originali nella radice del package):

```bash
Rscript data-raw/build_all.R
```

## Citazione

Montaletti, G. (2026). *golDatasets: Dataset canonici del Programma GOL*. Versione 0.1.0. <https://github.com/gmontaletti/golDatasets>

## Licenza

MIT © Giampaolo Montaletti

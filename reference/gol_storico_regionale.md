# Storico GOL regionale 2022-2025 (temi A1, B, F, H)

Unione dei quattro file `gol_{A1,B,F,H}_long.csv` di `dataset_long/`,
ristretta alle righe con `quality_flag == "ok"` e ad anchor regionale
canonico (22 etichette). Copre 27 report di monitoraggio ANPAL / MLPS /
INAPP dal 2022-09 al 2025-12.

## Usage

``` r
gol_storico_regionale
```

## Format

Un `data.table` con le colonne originali del long format (`file`,
`ente`, `data_riferimento`, `tema`, `caption_num`, `caption_title`,
`page`, `anchor`, `col_index`, `header_above`, `valore_raw`,
`valore_num`, `unit_guess`, `quality_flag`).

## Source

ANPAL, MLPS, INAPP — Note di monitoraggio Programma GOL, 2022-2025.
Estrazione automatica da PDF.

## Details

La decodifica semantica di `col_index` non e' inclusa: per ricostruire
il significato di ogni colonna usare `caption_title` + `header_above`,
tenendo conto di tre rotture di serie documentate
(`dataset_long/README.md`):

1.  Cambio unita' (presi in carico -\> individui) nel 2025.

2.  Cambio regola di assegnazione regionale (regione di presa in carico
    -\> regione di ultima presa in carico) nel 2025.

3.  Ampliamento 4 -\> 5 percorsi GOL nel 2025 (per A1, F, H).

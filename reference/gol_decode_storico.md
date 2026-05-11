# Applica il decoder semantico a gol_storico_regionale

Aggiunge le colonne `variabile`, `caratteristica`, `modalita`,
`percorso`, `unita`, `confidenza` derivate dal lookup `storico_decoder`
su `(tema, caption_num, col_index, era)`. La colonna `era` viene
calcolata al volo da `data_riferimento` (cut a 2025-01-01).

## Usage

``` r
gol_decode_storico(data = NULL, min_confidenza = "low")
```

## Arguments

- data:

  Un `data.table` con la stessa struttura di `gol_storico_regionale`. Se
  `NULL` (default), usa il dataset esposto.

- min_confidenza:

  Tiene solo le righe con `confidenza >=` il livello indicato. Default
  `"low"` (tutte). Per analisi rigorose usare `"high"`.

## Value

Un `data.table` con le colonne originali piu' quelle semantiche.

## Examples

``` r
d <- gol_decode_storico()
d[tema == "A1" & confidenza == "high",
  .(data_riferimento, anchor, variabile, percorso, valore_num)]
#>      data_riferimento         anchor              variabile percorso valore_num
#>                <IDat>         <char>                 <char>   <char>      <num>
#>   1:       2022-12-31        Abruzzo presi_in_carico_totale     <NA>       5165
#>   2:       2022-12-31     Basilicata presi_in_carico_totale     <NA>       2450
#>   3:       2022-12-31       Calabria presi_in_carico_totale     <NA>       9707
#>   4:       2022-12-31       Campania presi_in_carico_totale     <NA>      38127
#>   5:       2022-12-31 Emilia-Romagna presi_in_carico_totale     <NA>      28071
#>  ---                                                                           
#> 583:       2025-01-31        Toscana presi_in_carico_totale     <NA>     161588
#> 584:       2025-01-31         Totale presi_in_carico_totale     <NA>    1808684
#> 585:       2025-01-31         Umbria presi_in_carico_totale     <NA>      38794
#> 586:       2025-01-31  Valle d'Aosta presi_in_carico_totale     <NA>       2859
#> 587:       2025-01-31         Veneto presi_in_carico_totale     <NA>     132480
```

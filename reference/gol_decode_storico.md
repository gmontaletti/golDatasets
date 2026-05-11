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
#>       data_riferimento  anchor           variabile
#>                 <IDat>  <char>              <char>
#>    1:       2022-12-31 Abruzzo presi_in_carico_ass
#>    2:       2022-12-31 Abruzzo presi_in_carico_ass
#>    3:       2022-12-31 Abruzzo presi_in_carico_ass
#>    4:       2022-12-31 Abruzzo presi_in_carico_ass
#>    5:       2022-12-31 Abruzzo  presi_in_carico_pc
#>   ---                                             
#> 5073:       2025-01-31  Veneto  presi_in_carico_pc
#> 5074:       2025-01-31  Veneto presi_in_carico_ass
#> 5075:       2025-01-31  Veneto  presi_in_carico_pc
#> 5076:       2025-01-31  Veneto presi_in_carico_ass
#> 5077:       2025-01-31  Veneto  presi_in_carico_pc
#>                            percorso valore_num
#>                              <char>      <num>
#>    1:    1_reinserimento_lavorativo     5165.0
#>    2:    2_aggiornamento_upskilling     2811.0
#>    3: 3_riqualificazione_reskilling     1729.0
#>    4:           4_lavoro_inclusione      260.0
#>    5:    1_reinserimento_lavorativo       51.8
#>   ---                                         
#> 5073: 3_riqualificazione_reskilling       48.5
#> 5074:           4_lavoro_inclusione       41.5
#> 5075:           4_lavoro_inclusione        6.7
#> 5076:   5_ricollocazione_collettiva        3.1
#> 5077:   5_ricollocazione_collettiva        0.2
```

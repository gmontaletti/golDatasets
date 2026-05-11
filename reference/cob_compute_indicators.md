# Calcola indicatori derivati dai flussi COB

A partire dal dataset long `cob_regionale_trimestrale`, ricompone i
flussi di avviamenti e cessazioni in un'unica riga per
`(regione, anno, trimestre)` e calcola gli indicatori derivati piu'
usati per analisi di mercato del lavoro regionale.

## Usage

``` r
cob_compute_indicators(data = NULL)
```

## Arguments

- data:

  Un `data.table` con la stessa struttura di
  `cob_regionale_trimestrale`. Se `NULL` (default), usa il dataset
  esposto dal package.

## Value

Un `data.table` in formato wide con una riga per
`(regione, anno, trimestre)` e le seguenti colonne aggiuntive rispetto
alle chiavi:

- avviamenti_rapporti, cessazioni_rapporti:

  numero di rapporti avviati / cessati nel trimestre.

- avviamenti_lavoratori, cessazioni_lavoratori:

  numero di lavoratori distinti coinvolti.

- saldo_rapporti:

  avviamenti_rapporti - cessazioni_rapporti.

- saldo_lavoratori:

  avviamenti_lavoratori - cessazioni_lavoratori.

- rotation_avviamenti, rotation_cessazioni:

  rapporti per lavoratore, indicatore di rotazione.

- yoy_avviamenti, yoy_cessazioni, yoy_saldo:

  variazione percentuale sul corrispondente trimestre dell'anno
  precedente (lag 4).

- data_inizio_trimestre:

  `IDate`, primo giorno del trimestre.

## Examples

``` r
ind <- cob_compute_indicators()
# Saldo netto trimestrale Emilia-Romagna
ind[regione == "Emilia-Romagna",
    .(anno, trimestre, saldo_rapporti)]
#>      anno trimestre saldo_rapporti
#>     <int>     <int>          <num>
#>  1:  2017         1          81669
#>  2:  2017         2          62142
#>  3:  2017         3         -15224
#>  4:  2017         4         -64240
#>  5:  2018         1          91331
#>  6:  2018         2          43090
#>  7:  2018         3         -19513
#>  8:  2018         4         -65327
#>  9:  2019         1          89479
#> 10:  2019         2          44217
#> 11:  2019         3         -12400
#> 12:  2019         4         -75201
#> 13:  2020         1          64884
#> 14:  2020         2           3186
#> 15:  2020         3          19292
#> 16:  2020         4         -64620
#> 17:  2021         1          75937
#> 18:  2021         2          48403
#> 19:  2021         3           5206
#> 20:  2021         4         -61194
#> 21:  2022         1          85634
#> 22:  2022         2          41946
#> 23:  2022         3         -13817
#> 24:  2022         4         -69403
#> 25:  2023         1          96358
#> 26:  2023         2          42356
#> 27:  2023         3          24919
#> 28:  2023         4         -72190
#> 29:  2024         1         113565
#> 30:  2024         2          15306
#> 31:  2024         3           -763
#> 32:  2024         4         -79796
#> 33:  2025         1         103481
#> 34:  2025         2          16377
#> 35:  2025         3          -7382
#>      anno trimestre saldo_rapporti
#>     <int>     <int>          <num>
```

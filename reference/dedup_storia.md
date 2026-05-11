# Deduplica un dataset di storia lunga GOL

Applica regole di deduplicazione in ordine sulla chiave logica indicata:

1.  se piu' righe hanno `valore == 0` o `NA`, mantiene la prima riga con
    valore non-zero/non-NA.

2.  se i valori sono identici tra fonti diverse, mantiene una sola riga
    (la fonte di priorita' piu' alta).

3.  se i valori differiscono, mantiene la riga della fonte di priorita'
    piu' alta (inapp_focus \> storico_INAPP \> MLPS \> ANPAL \> ALTRO).

## Usage

``` r
dedup_storia(data, keys)
```

## Arguments

- data:

  Un `data.table` long con almeno le colonne `valore` e `fonte`.

- keys:

  Vettore character delle colonne che identificano la chiave logica di
  un osservazione (es.
  `c("data_riferimento", "regione", "variabile", "percorso")`).

## Value

Un `data.table` deduplicato con le stesse colonne, una riga per chiave
logica.

## Examples

``` r
dt <- data.table::data.table(
  data_riferimento = as.Date("2025-01-31"),
  regione = "Lombardia", variabile = "x", percorso = NA,
  valore = c(0, 100, 100),
  fonte  = c("storico_ANPAL", "storico_MLPS", "storico_INAPP")
)
dedup_storia(dt, keys = c("data_riferimento", "regione",
                            "variabile", "percorso"))
#>    data_riferimento   regione variabile percorso valore         fonte
#>              <Date>    <char>    <char>   <lgcl>  <num>        <char>
#> 1:       2025-01-31 Lombardia         x       NA    100 storico_INAPP
# Tiene la riga storico_INAPP (priorita' piu' alta tra le non-zero)
```

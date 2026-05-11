# Estrae una serie di caratteristiche dei beneficiari

Estrae una serie di caratteristiche dei beneficiari

## Usage

``` r
gol_storia_caratteristiche_series(
  caratteristica,
  modalita = NULL,
  regione = NULL,
  min_confidenza = "medium"
)
```

## Arguments

- caratteristica:

  Nome della caratteristica (`"genere"`, `"classe_eta"`,
  `"cittadinanza"`, `"durata_disoccupazione"`).

- modalita:

  Vettore di modalita' (`"Maschi"`, `"Femmine"`, `"15-29"` ...). `NULL`
  = tutte.

- regione:

  Filtro regionale. `NULL` = tutte.

- min_confidenza:

  Default `"medium"`.

## Value

Un `data.table` pronto per `plot_timeline(group = "modalita")`.

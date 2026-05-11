# Estrai una serie temporale pronta per plot da `gol_inapp_mensile`

Filtra `gol_inapp_mensile` lungo tavola, variabile, percorso, etichetta
regionale e unita' di misura, restituendo un `data.table` con le colonne
`data`, `valore` (ed eventualmente `regione`, `percorso`) pronto per
essere passato a
[`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md).

## Usage

``` r
gol_extract_series(
  data = NULL,
  variabile,
  etichetta = NULL,
  tavola = NULL,
  percorso = NULL,
  unita_misura = "valore_assoluto"
)
```

## Arguments

- data:

  Un `data.table` con la stessa struttura di `gol_inapp_mensile`. Se
  `NULL` (default), usa il dataset esposto.

- variabile:

  Nome della variabile (es. `"occupati_totale"`, `"raggiunti"`,
  `"individui"`, `"con_politica"`).

- etichetta:

  Vettore di etichette regionali. `NULL` (default) per tutte; passare ad
  esempio `"Italia"` o `"Totale"` per l'aggregato nazionale, o un
  vettore di regioni per il confronto.

- tavola:

  Numero di tavola (1.1, 1.2, 2.1, 2.2). `NULL` per inferenza automatica
  dalla `variabile`.

- percorso:

  Filtro sulla colonna `percorso`. Default `NULL` (nessun filtro: le
  variabili che esistono per un solo percorso restituiscono una serie
  unica, quelle che si decompongono mantengono la colonna `percorso`).
  Passare `""` per restringere all'aggregato senza disaggregazione, o un
  singolo percorso (`"1_reinserimento_lavorativo"`, ...) per filtrare.

- unita_misura:

  Default `"valore_assoluto"`. Altri valori possibili: `"percentuale"`,
  `"percentuale_riga"`.

## Value

Un `data.table` con almeno le colonne `data` (IDate) e `valore`
(numeric). Se `etichetta` ha piu' valori, e' presente anche `regione`.
Se `percorso = NULL`, e' presente anche `percorso`.

## Details

La tavola viene dedotta automaticamente dalla `variabile` quando
`tavola = NULL`. Ad esempio `variabile = "occupati_totale"` implica
`tavola == 2.2`, `variabile = "raggiunti"` implica `tavola == 2.1`,
`variabile = "individui"` o `"totale"` implicano `tavola == 1.1`.

## Examples

``` r
# Occupati totale, Emilia-Romagna
s1 <- gol_extract_series(variabile = "occupati_totale",
                         etichetta = "Emilia-Romagna")

# Confronto multi-regione
s2 <- gol_extract_series(variabile = "raggiunti",
                         etichetta = c("Emilia-Romagna", "Lombardia",
                                       "Campania", "Sicilia"))

# Decomposizione per percorso (Emilia-Romagna)
s3 <- gol_extract_series(variabile = "presi_in_carico",
                         etichetta = "Emilia-Romagna",
                         percorso = NULL)
```

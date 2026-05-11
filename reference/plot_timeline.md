# Disegna una timeline con eventuali annotazioni di rotture di metodo

Funzione generica per visualizzare una serie temporale long. Pensata per
i tre dataset del package ma applicabile a qualunque `data.frame` con
una colonna data e una colonna valore. Le rotture di metodo (per i dati
GOL nel 2025) si attivano passando un data frame al parametro
`ruptures`; tipicamente `gol_method_ruptures`.

## Usage

``` r
plot_timeline(
  data,
  x = "data",
  y = "valore",
  group = NULL,
  ruptures = NULL,
  title = NULL,
  subtitle = NULL,
  y_label = NULL,
  date_breaks = "6 months",
  smooth = FALSE
)
```

## Arguments

- data:

  Un `data.frame` o `data.table` in formato long con almeno una colonna
  data e una colonna numerica.

- x:

  Nome (character) della colonna data sull'asse orizzontale. Default:
  `"data"`.

- y:

  Nome della colonna numerica da plottare. Default: `"valore"`.

- group:

  Nome opzionale della colonna di raggruppamento (mappata su colore +
  tipologia di linea). Lascia `NULL` per una singola serie.

- ruptures:

  Data frame con le rotture da annotare. Deve contenere colonne `data`
  (date) ed `evento` (character). Passa `gol_method_ruptures` per le
  rotture standard GOL. `NULL` (default) per nessuna annotazione.

- title, subtitle:

  Titolo e sottotitolo del plot.

- y_label:

  Etichetta dell'asse Y.

- date_breaks:

  Stringa passata a
  [`ggplot2::scale_x_date`](https://ggplot2.tidyverse.org/reference/scale_date.html)
  (es. `"6 months"`, `"1 year"`). Default: `"6 months"`.

- smooth:

  Se `TRUE` aggiunge un geom_smooth(method = "loess").

## Value

Un oggetto `ggplot`.

## Examples

``` r
if (FALSE) { # \dontrun{
library(data.table)
serie <- gol_inapp_mensile[
  tavola == 2.2 & etichetta == "Emilia-Romagna" &
  variabile == "occupati_totale" & percorso == "",
  .(data = data_riferimento, valore)
]
plot_timeline(serie, ruptures = gol_method_ruptures,
              title = "Occupati GOL - Emilia-Romagna",
              y_label = "N. occupati")
} # }
```

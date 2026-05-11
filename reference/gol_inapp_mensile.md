# Serie INAPP Focus GOL mensile (2024-06 -\> 2025-12)

Long format dei 12 report INAPP Focus GOL, ciascuno con quattro tavole
regionali (1.1, 1.2, 2.1, 2.2/3.1). Estratto da
`INAPP GOL/csv_long/tab_long_completo.csv`, prodotto dall'estrattore
Python `estrai_tavole_inapp_gol.py`.

## Usage

``` r
gol_inapp_mensile
```

## Format

Un `data.table` con le seguenti colonne:

- report_id:

  Identificativo del report sorgente (UUID o nome file).

- data_riferimento:

  `IDate`, data di riferimento dei dati.

- tavola:

  Numero della tavola (1.1, 1.2, 2.1, 2.2).

- titolo_tabella:

  Titolo completo della tabella nel PDF.

- dimensione:

  `"regione"` o `"percorso"`.

- etichetta:

  Valore della dimensione (22 etichette regionali canoniche, o nome del
  percorso).

- variabile:

  Nome semantico della variabile (es. `"raggiunti"`, `"con_politica"`,
  `"occupati_totale"`, `"incidenza_pc"`).

- percorso:

  Solo per tavola 2.2: uno dei 5 percorsi GOL; vuoto altrove.

- unita_misura:

  `"valore_assoluto"`, `"percentuale"` o `"percentuale_riga"`.

- valore:

  Valore numerico parsato.

## Source

INAPP, Note di monitoraggio "Focus GOL", 2024-2025. Estrazione
automatica via Poppler (`pdftotext`) + parser Python custom.

## See also

`verifica_coerenza.md` per i controlli di consistenza inter-tavola.

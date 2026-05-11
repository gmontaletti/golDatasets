# Comunicazioni Obbligatorie regionali trimestrali (2017-Q1 -\> 2025-Q3)

Flussi di avviamenti e cessazioni dei rapporti di lavoro per Regione e
trimestre, estratti dagli allegati statistici INPS "Allegato-IV-
Trimestre". Nomi regionali armonizzati alle 21 etichette canoniche GOL;
marker `N.D.` e `Totale` sono esclusi.

## Usage

``` r
cob_regionale_trimestrale
```

## Format

Un `data.table` con le seguenti colonne:

- regione:

  Etichetta regionale canonica (21 valori).

- anno:

  Anno (2017-2025).

- trimestre:

  Trimestre (1-4).

- trimestre_roman:

  Trimestre in numeri romani (I-IV).

- flusso:

  `"avviamenti"` o `"cessazioni"`.

- rapporti:

  Numero di rapporti di lavoro avviati / cessati.

- lavoratori:

  Numero di lavoratori distinti coinvolti.

- media:

  Rapporti per lavoratore (rapporti / lavoratori).

- file_origine:

  Nome del file XLSX di origine.

- data_inizio_trimestre:

  `IDate`, primo giorno del trimestre, per facilitare il merge con serie
  mensili.

## Source

INPS, "Allegato IV - Trimestre" delle Comunicazioni Obbligatorie,
2017-2025.

## Details

Utile come baseline esogena per studi di impatto del Programma GOL sul
mercato del lavoro locale.

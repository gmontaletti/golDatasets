---
title: Verifica coerenza tavole INAPP Focus GOL
data: 2026-05-09
---

## Sintesi

Lo script R presente nel progetto (`estrai_tavole_inapp_gol.R`) non era applicabile al
corpus PDF in archivio per quattro motivi accertati nei test:

1. il pattern del nome file (`^INAPP_FocusGOL.*\\.pdf$`) non corrisponde ai nomi
   adottati dal sistema di knowledge (UUID), perciò la pipeline R restituiva
   sempre zero file e zero righe;
2. il parser di Tavola 1.1 era cablato a sette valori numerici per riga, mentre
   il report del 30/06/2024 riporta soltanto tre annualità (2022-2024), per un
   totale di sei valori per riga; tutte le righe di quel report producevano
   `NA`;
3. il regex per Friuli-Venezia Giulia non ammette la sigla `FVG` impiegata nei
   tracciati pre-2025; le righe corrispondenti finivano in `NA`;
4. il parser non gestisce le anomalie tipografiche introdotte dall'estrazione
   di alcuni PDF (lettering spaziato come `Ba s i l i ca ta`, nomi spezzati su
   due righe come `Friuli-Venezia\nGiulia`), perché lavora su stringhe esatte.

A queste si aggiungono due varianti di intestazione che lo script R gestisce
parzialmente: l'intestazione `Tabella 2.2 - Programma GOL` (con trattino) del
report del 30/06/2024, e la rinumerazione `Tabella 2.2 → Tabella 3.1` nel
report del 31/12/2025.

Per superare questi vincoli è stato riscritto il parser in Python
(`estrai_tavole_inapp_gol.py`). La nuova pipeline produce 12 estrazioni
consistenti, con 22 righe regionali in tutte le tavole `1.1`, `1.2`, `2.1`
e 26 righe (22 regioni + 4 percorsi) in tutte le tavole `2.2/3.1`.

## Verifiche effettuate

| Controllo | Esito |
|---|---|
| Copertura righe tavola 1.1 | 22/22 in tutti i 12 report |
| Copertura righe tavola 1.2 | 22/22 in tutti i 12 report |
| Copertura righe tavola 2.1 | 22/22 in tutti i 12 report |
| Copertura righe tavola 2.2/3.1 | 22 regioni + 4 percorsi in tutti i 12 report |
| Valori NA nel CSV unificato | 0 su 10.922 record |
| Somma annualità = totale (tav. 1.1) | OK su tutte le 264 righe (delta max 1) |
| Somma % di riga ≈ 100 (tav. 1.2) | OK (delta max 0,20 punti) |
| Somma assoluti percorsi (1.2) = totale prese in carico (1.1) | OK (delta max < 5) |
| Rapporto B/A ≈ percentuale pubblicata (tav. 2.1) | Coincidenza esatta |
| Rapporto B/A ≈ percentuale pubblicata (tav. 2.2) | Coincidenza esatta |
| Coerenza inter-tavola individui (1.1) ≡ raggiunti (2.1) | OK in 11 report su 12 |

L'unica eccezione riguarda il report del 30/06/2024, in cui sei valori di
`individui` (Tavola 1.1) differiscono di 50-131 unità rispetto ai
`raggiunti` (Tavola 2.1). La discrepanza è presente nel PDF di origine ed è
imputabile a un consolidamento successivo dei dati di una delle due tavole.
Lo scarto è inferiore allo 0,1% del totale ed è documentato in
`diagnostica.csv`.

## Colonne con soli valori NA

Sull'intero corpus è presente un unico caso di colonna interamente NA:
nel file `tab_1_1_wide.csv`, la colonna `2025` è vuota per il report
`cc0c4fd8-2feb-4f90-8c6d-339383a25091` (dati al 30/06/2024). È il
comportamento atteso: il report del giugno 2024 non riporta la colonna 2025.
Nessun'altra colonna è interamente NA in nessun altro report.

## Output

Cartella `csv_long/`:

- `tab_1_1_long.csv`, `tab_1_2_long.csv`, `tab_2_1_long.csv`,
  `tab_2_2_long.csv`: ciascuna tavola in formato lungo
- `tab_long_completo.csv`: unione delle quattro tavole con schema
  `data_riferimento | report_id | tavola | dimensione | etichetta |
  variabile | percorso | unita_misura | valore`
- `tab_*_wide.csv`: corrispondenti versioni wide per controllo manuale
- `diagnostica.csv`: numero di righe estratte per report e tavola

## Esecuzione

```bash
python3 estrai_tavole_inapp_gol.py \
    --input-dir /percorso/ai/PDF \
    --output-dir csv_long
```

Lo script richiede `pdftotext` (Poppler) come backend principale e
`pdfplumber` come fallback puro Python. Il pattern dei nomi file è
configurabile via `--pattern`.

# Dataset GOL in formato lungo — documentazione

## Contenuto della cartella

La cartella contiene 11 file CSV in formato lungo (long format), uno per ciascuna famiglia tematica di tabelle ricorrenti identificata nei 27 report di monitoraggio del Programma GOL archiviati in `rapporti/timeline_gol/`. La granularità di ogni file è il singolo valore numerico, accompagnato dal contesto necessario a ricostruire la cella di provenienza nella tabella originaria.

| File | Famiglia | File sorgente coperti | Record |
|---|---|---:|---:|
| `gol_A1_long.csv` | Presi in carico × regione × percorso | 27 | 3.365 |
| `gol_A2_long.csv` | Presi in carico × regione × target PNRR | 6 | 861 |
| `gol_A3_long.csv` | Presi in carico × regione: tassi di crescita / incidenza | 5 | 396 |
| `gol_B_long.csv` | Presi in carico × regione × caratteristiche anagrafiche | 27 | 6.996 |
| `gol_E_long.csv` | Patto di servizio attivo × target × regione | 13 | 1.410 |
| `gol_F_long.csv` | Beneficiari con almeno una politica avviata × regione | 20 | 6.825 |
| `gol_H_long.csv` | Occupazione/esiti occupazionali × regione | 18 | 3.309 |
| `gol_I_long.csv` | Occupazione × tipo di contratto × percorso | 15 | 300 |
| `gol_J_long.csv` | Tassi di occupazione × caratteristiche dei beneficiari | 3 | 137 |
| `gol_K_long.csv` | Formazione: partecipanti, attività avviate/concluse | 4 | 978 |
| `gol_L_long.csv` | Esiti occupazionali × area geografica (Nord/Centro/Sud) | 2 | 265 |

## Schema dei CSV

Tutti i file condividono lo stesso schema, in modo da consentire l'unione in un unico data frame se utile per analisi cross-tema.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `file` | string | percorso relativo del PDF di origine, es. `2025/INAPP_Focus-GOL_17-2025.pdf` |
| `ente` | string | ente curatore: `ANPAL`, `MLPS`, `INAPP` |
| `data_riferimento` | date (YYYY-MM-DD) | data di riferimento dei dati, estratta dal nome del file e dal testo |
| `tema` | string | codice della famiglia tematica (`A1`, `A2`, `A3`, `B`, `E`, `F`, `H`, `I`, `J`, `K`, `L`) |
| `caption_num` | string | numerazione della tabella nel PDF, es. `1.1`, `2.5` |
| `caption_title` | string | titolo completo della didascalia |
| `page` | integer | pagina del PDF in cui si trova la riga |
| `anchor` | string | etichetta di riga (regione, area geografica, tipo di contratto, caratteristica) |
| `col_index` | integer (0-based) | posizione della colonna nella tabella originaria |
| `header_above` | string | testo delle righe di intestazione che precedono la prima riga dati, concatenato con ` \| ` |
| `valore_raw` | string | token originale come letto dal PDF, es. `1.234`, `12,3`, `n.d.` |
| `valore_num` | numeric (nullable) | valore parsato in formato numerico (separatore decimale `.`) |
| `unit_guess` | string | euristica sull'unità: `count`, `percent`, `decimal`, `missing`, `error` |
| `quality_flag` | string | qualità dell'estrazione: `ok`, `best_effort`, `no_data_extracted` |

## Convenzioni di codifica

L'`anchor` è normalizzato a una forma canonica indipendente dalla capitalizzazione del PDF di origine. Le 22 etichette regionali standard sono: `Abruzzo`, `Basilicata`, `P.A. Bolzano`, `Calabria`, `Campania`, `Emilia-Romagna`, `Friuli-Venezia Giulia`, `Lazio`, `Liguria`, `Lombardia`, `Marche`, `Molise`, `Piemonte`, `Puglia`, `Sardegna`, `Sicilia`, `Toscana`, `P.A. Trento`, `Umbria`, `Valle d'Aosta`, `Veneto`, `Italia`/`Totale`. Le aree geografiche sono normalizzate a `Nord-Ovest`, `Nord-Est`, `Nord`, `Centro`, `Sud`, `Sud e Isole`, `Mezzogiorno`, `Isole`, `Italia`.

L'`unit_guess` è euristica e va verificata caso per caso usando `header_above`. La regola è la seguente: un token contenente una virgola è interpretato come decimale e classificato `percent` se compreso tra -1 e 1000, altrimenti `decimal`; un token senza virgola e senza punto, o con punto come separatore delle migliaia, è classificato `count`. I trattini e i marker `n.d.` producono `unit_guess = missing` con `valore_num = null`.

Il `col_index` è 0-based e riflette la posizione del token nella riga estratta dal PDF, dopo aver rimosso l'etichetta dell'`anchor`. La mappatura `col_index → significato semantico` non è codificata nel CSV ma è ricostruibile dal campo `header_above` insieme al `caption_title`. Per i temi A1, A2, A3, B, E, F, H questa mappatura è generalmente stabile all'interno di uno stesso file (`file × caption_num` definisce una tabella, e il numero di colonne è fisso).

## Quality flag

Il valore `ok` indica che la riga è stata estratta da una tabella regionale ben strutturata con anchor riconosciuto. Si applica ai temi A1, A2, A3, B, E, F, H quando l'estrazione produce almeno un token numerico. Coverage: 24.162 record su 24.842 totali (97,3%).

Il valore `best_effort` indica che l'estrazione è avvenuta su una tabella con struttura più variabile (temi I, J, K, L) o con anchor non regionali. I valori sono comunque utilizzabili ma è opportuno verificare manualmente la mappatura `col_index → variabile` per ogni `caption_num`. Coverage: 1.680 record (6,8%).

Il valore `no_data_extracted` indica che la didascalia è stata identificata ma nessuna riga dati è stata individuata, tipicamente perché la tabella è codificata come immagine raster o perché la struttura è non tabellare. Sono presenti 7 occorrenze su 24.842 record. Le righe con questo flag riportano i campi `caption_*` e `header_above` ma hanno `anchor`, `col_index` e `valore_*` nulli.

## Cambiamenti di definizione lungo la serie

Tre rotture di serie meritano attenzione nelle analisi temporali.

Il **passaggio "presi in carico" → "individui coinvolti"** avviene con il formato INAPP del 2025. L'unità di osservazione cambia da evento (presa in carico) a persona (individuo); le tabelle del 2025 riportano spesso entrambi i conteggi affiancati (`prese in carico` cumulate vs `individui raggiunti`). Si raccomanda di costruire serie storiche separate in base all'unità di osservazione e di documentare la trasformazione.

Il **passaggio "regione di presa in carico" → "regione di ultima presa in carico"** ricorre nei caption_title del 2025 e modifica la regola di assegnazione regionale per gli individui che presentano più prese in carico in regioni diverse. L'effetto sulla composizione regionale degli stock può essere non trascurabile e va testato confrontando i valori del totale Italia con la somma dei valori regionali.

L'**ampliamento dei percorsi GOL da quattro a cinque** con l'introduzione del percorso "Ricollocazione collettiva" si riflette nel numero di colonne delle tabelle A1, F, H, I a partire dal 2025. Il `col_index` non è quindi confrontabile direttamente fra il formato pre-2025 e post-2025 per questi temi.

## Raccomandazioni d'uso

Il dataset è progettato per analisi in formato lungo. La serie storica per regione si costruisce filtrando per `tema`, raggruppando per `data_riferimento`, `anchor`, `col_index` (eventualmente arricchito con la decodifica semantica della colonna). Per analisi che richiedono il merge tra temi (per esempio collegare presi in carico A1 con esiti occupazionali H sulla stessa regione e periodo), la chiave di join è `(file, anchor, data_riferimento)` o, se si vuole costruire una serie storica continua, `(ente, data_riferimento, anchor)` accettando le rotture di serie sopra documentate.

Lo script di estrazione è disponibile in `outputs/extract_long.py`. Per riprodurre il dataset è sufficiente eseguire:

```bash
python3 extract_long.py
```

avendo `pdfplumber` installato e i PDF nella loro posizione originale.

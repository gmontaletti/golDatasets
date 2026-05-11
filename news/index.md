# Changelog

## golDatasets 0.7.0

### Java + tabula attivati

Con l’installazione di Temurin 21 il backend `tabula` torna disponibile.
Il parser `estrai_tavole_focus_gol_all.py` ora estrae con `tabula`
(invece di `pdfplumber`), con netto miglioramento sulla qualita’ di
estrazione delle tabelle complesse:

| Tabella                 | pdfplumber (mediana) | tabula (mediana) |
|-------------------------|---------------------:|-----------------:|
| 1.3 caratteristiche     |            2.5 righe |           **24** |
| 1.4 percorsi            |                    4 |           **27** |
| 1.5 vulnerabilita’      |                    3 |           **19** |
| 2.3 formazione digitale |                  6.5 |            **8** |

### Mapper INAPP focus_gol_all (parziali)

- [`build_inapp_focus_long()`](https://gmontaletti.github.io/golDatasets/reference/build_inapp_focus_long.md):
  orchestratore che invoca i mapper su tutti i CSV in
  `INAPP GOL/focus_gol_all/<report_id>/`.
- `.map_tab_1_5()`: tabella 1.5 “patto di servizio attivo per target ×
  regione” - **219 righe** estratte (~2 report con struttura canonica).
  Output: `caratteristica = "target_patto_servizio"` con modalita
  `Totale, SFL_domanda_accolta, ADI_attivabili, NASpI_domanda_presentata, Altri_disoccupati`.
- `.map_tab_2_3()`: tabella “corsi di formazione competenze digitali”
  per dimensione (area geografica, percorso, eta’, genere, …) - **88
  righe** estratte (solo report 17/2025 ha la struttura canonica).
  Output: `corsi_totali`, `corsi_completati` con `unita = count` o
  `percentage`.

### Dataset aggiornati

| Dataset                      | v0.6.0 |     v0.7.0 |
|------------------------------|-------:|-----------:|
| `gol_storia_caratteristiche` |  6.996 |  **7.215** |
| `gol_storia_esiti`           | 15.427 | **15.515** |

### Future work (v0.8.0)

Non ancora coperto dai mapper:

- **Tab 1.3 / 1.4** caratteristiche socio-anagrafiche per regione: 22+
  righe × 12 report disponibili, ma duplicano informazione già nel tema
  B del decoder storico. Va decisa la strategia di deduplicazione.
- **Tab 1.6** patto di servizio per target × caratteristiche
  trasversali: schema a sezioni complesso, richiede mapper dedicato.
- **Tab 1.7** composizione patto di servizio per regione: 38 colonne
  irregolari, richiede header recovery custom.
- **Tab 1.5** versione “per percorso” (presente nei report mensili in
  alternativa alla versione “per regione”): mapper aggiuntivo che
  riconosca lo schema alternativo.

## golDatasets 0.6.0

### Refinement del decoder semantico

Aggiunti tre blocchi di **mapping posizionali** in
`data-raw/build_storico_decoder.R` per i temi con schema stabile:

- Tema B (caption 3, 1.3, 1.4): mapping deterministico delle 12 colonne
  anagrafiche (`Maschi/Femmine/Totale`, `15-29/30-54/55+/Totale`,
  `Italiana/Straniera/Totale`, `>=6mesi/>=12mesi`).
- Tema H caption 2.2: mapping di 6 variabili occupazionali standard
  (`raggiunti`, `occupati_totale`, `nuovi_occupati`, `occupati_pc`,
  `quota_nuovi_su_occ`, `gia_occupati`).
- Tema F caption 2.1: mapping di 3 variabili sulle politiche
  (`presi_in_carico_totale`, `con_politica_avviata`,
  `con_politica_avviata_pc`).

Vectorizzazione di `classify_unita()` per consentire l’uso in data.table
con vettori di righe.

### Risultati

- `storico_decoder`: 228 righe; distribuzione `low` ridotta da **53 a
  20** (-62%). Tema B: 0 low residui. Tema F: 0 low residui. Tema H: 17
  low (-37%).
- `gol_storia_caratteristiche`: 4.262 -\> **6.996 righe** (+64%), grazie
  ai 27 mapping anagrafici di tema B ora classificati `high`.
- `gol_storia_esiti`: 13.561 -\> **15.427 righe** (+14%), grazie alle
  nuove variabili F e H decodificate.
- `gol_storia_volumi`: 9.194 righe (invariato).

### Sub-task differiti a v0.7.0

I 6 mapper INAPP `focus_gol_all` previsti dal piano sono **rimandati**:

- Tab 1.3, 1.4, 1.5, 2.3: estrazione `pdfplumber` produce 1-5 righe per
  report (header multi-riga non parsato), inutilizzabile senza un parser
  PDF specializzato.
- Tab 1.6, 1.7: estraggono 20-36 righe ma con strutture incompatibili
  con le ipotesi del piano (1.6 non e’ per regione ma trasversale per
  target × caratteristica; 1.7 ha 38 colonne irregolari).

La risoluzione richiede un parser PDF custom (probabilmente
`tabula-java` se Java diventa disponibile, o un pre-processore
`pdfplumber` con regole di header recovery dedicate per ciascuna
tabella). Differito a v0.7.0.

## golDatasets 0.5.0

### Decoder semantico storico

- `storico_decoder` (~228 righe): mappa (`tema`, `caption_num`,
  `col_index`, `era`) a (`variabile`, `caratteristica`, `modalita`,
  `percorso`, `unita`, `confidenza`). Costruito via regex su
  `header_above` modale; editabile manualmente da
  `inst/extdata/storico_decoder.csv`.
- [`gol_decode_storico()`](https://gmontaletti.github.io/golDatasets/reference/gol_decode_storico.md):
  applica il decoder a `gol_storico_regionale`, aggiungendo `era` e le
  colonne semantiche. Supporta filtro `min_confidenza` (high / medium /
  low).

### Storia lunga 2022-2025

Tre dataset tematici long format che integrano storico ANPAL/MLPS e
INAPP mensile:

- `gol_storia_volumi` (~9.200 righe): presi in carico × regione ×
  percorso, da 2022-09 a 2025-12.
- `gol_storia_caratteristiche` (~4.300 righe): genere, classe eta’,
  cittadinanza, durata disoccupazione.
- `gol_storia_esiti` (~13.600 righe): occupazione 60/90/180gg,
  politiche, LEP, formazione, occupati totali.

Tre funzioni di estrazione compatibili con
[`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md):

- `gol_storia_volumi_series(variabile, regione, percorso, ...)`
- `gol_storia_caratteristiche_series(caratteristica, modalita, regione, ...)`
- `gol_storia_esiti_series(variabile, regione, percorso, ...)`

### Documentazione

- Vignette `merge-gol-cob` estesa con sezione “Storia lunga 2022-2025”
  che mostra 3 grafici (presi in carico totale, composizione di genere,
  LEP-E) con cadenze miste (episodica 2022 → mensile 2025) e rotture
  annotate.

### Future work (v0.6.0)

- Mapper per le 6 nuove tabelle INAPP estratte in `focus_gol_all/` (1.3,
  1.4, 1.5, 1.6, 1.7, 2.3) — patto di servizio, vulnerabilita’,
  competenze digitali.
- Refinement manuale del CSV `storico_decoder.csv` per ridurre la quota
  di righe `confidenza = low` (53/228).

## golDatasets 0.4.0

### Quality assessment

- `gol_quality_classify(n_anchor, pct_na_valore, n_header_variants, n_col_index)`:
  classificatore basato su 4 metriche, produce 5 tier di severita’:
  `ok`, `review`, `rescan_low`, `rescan_high`, `rescan_critical`.
- `gol_storico_quality(data = NULL)`: applica il classificatore al
  dataset storico e produce una tabella diagnostica per
  `(file, tema, caption_num)`.

### Rebuild di gol_storico_regionale

- **INAPP A1/1.2**: le 10-11 estrazioni rotte (1-3 anchor invece di 21)
  in `dataset_long/gol_A1_long.csv` sono sostituite automaticamente con
  la versione decodificata di `INAPP GOL/csv_long/tab_1_2_long.csv`.
  Risultato: tutti i file INAPP per quella tavola hanno ora 22 anchor e
  10 col_index (5 percorsi × {abs, pc}).
- Aggiunta colonna `rescan_severity` con valori `ok`, `rescan_low`,
  `replaced_from_inapp_csv_long` per tracciare la provenienza.
- Le 3 estrazioni ANPAL 2022 e 3 ANPAL/ALTRO F/2.1 con 19-20 anchor sono
  marcate `rescan_low` e raccolte in `gol_rescan_recommendations` come
  future-work per re-estrazione manuale.

### Dataset esposti

- `gol_rescan_recommendations`: snapshot delle anomalie residue dopo la
  build, una riga per `(file, tema, caption_num)` da ri-estrarre.

### Documentazione

- Vignette `merge-gol-cob` estesa con sezione “Qualità delle estrazioni
  storiche”.

## golDatasets 0.3.0

### Funzioni

- [`gol_extract_series()`](https://gmontaletti.github.io/golDatasets/reference/gol_extract_series.md):
  pivota `gol_inapp_mensile` in serie pronte per
  [`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md).
  Inferenza automatica della tavola dalla `variabile`, supporto
  multi-regione (aggiunge la colonna `regione` quando le etichette sono
  piu’ di una), filtro opzionale su `percorso` e `unita_misura`.

### Documentazione

- Vignette `merge-gol-cob` estesa con tre nuovi grafici GOL: confronto
  multi-regione di `occupati_totale`, decomposizione per percorso (tav
  1.2) di Emilia-Romagna, confronto prestazioni LEP (tav 2.1) di
  Lombardia.

## golDatasets 0.2.0

### Funzioni

- [`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md):
  visualizza una timeline regionale con annotazione opzionale delle
  rotture di metodo. Usa palette CVD-safe Okabe-Ito di default per il
  confronto multi-serie.
- [`cob_compute_indicators()`](https://gmontaletti.github.io/golDatasets/reference/cob_compute_indicators.md):
  a partire da `cob_regionale_trimestrale` produce un wide-table con 11
  indicatori derivati per `(regione, anno, trimestre)`: saldi netti,
  indici di rotazione (rapporti / lavoratori) e variazioni YoY (lag 4
  trimestri).

### Dataset esposti

- `gol_method_ruptures`: 3 eventi di discontinuita’ metodologica nei
  dati GOL al passaggio del 2025 (cambio unita’, regola regionale, 4 -\>
  5 percorsi). Pensato per essere passato al parametro `ruptures` di
  [`plot_timeline()`](https://gmontaletti.github.io/golDatasets/reference/plot_timeline.md).

### Dipendenze

- Aggiunti `ggplot2` e `rlang` a Imports.

### Documentazione

- Vignette `merge-gol-cob` estesa con esempi grafici (rotture annotate,
  multi-regione, indicatori COB).

## golDatasets 0.1.0

Prima release del package.

### Dataset esposti

- `gol_inapp_mensile`: 10.922 osservazioni, 12 date di riferimento da
  2024-06-30 a 2025-12-31, 4 tavole INAPP Focus GOL (1.1, 1.2, 2.1,
  2.2/3.1).
- `gol_storico_regionale`: 20.493 osservazioni, 25 date da 2022-09-09 a
  2025-12-31, 4 temi GOL con schema stabile (A1, B, F, H),
  `quality_flag = "ok"` e anchor regionale canonico.
- `cob_regionale_trimestrale`: 1.470 osservazioni, 35 trimestri da
  2017-Q1 a 2025-Q3, 21 regioni canoniche, flussi `avviamenti` e
  `cessazioni`.

### Funzioni esposte

- [`build_gol_datasets()`](https://gmontaletti.github.io/golDatasets/reference/build_gol_datasets.md):
  rigenera i tre dataset dai CSV grezzi (`dataset_long/`,
  `INAPP GOL/csv_long/`, `cob/`) e li salva come `.rda` in `data/`.

### Documentazione

- Vignette `merge-gol-cob`: esempio di merge cross-dataset tra serie
  INAPP GOL e baseline COB INPS sulla chiave regionale canonica.
- Sito pkgdown configurato (`_pkgdown.yml`) con deploy via GitHub Action
  (`.github/workflows/pkgdown.yaml`) verso GitHub Pages.

### Convenzioni

- Etichette regionali armonizzate alle 22 canoniche definite in
  `dataset_long/README.md`.
- Nomi regionali COB normalizzati: `Bolzano/Bolzen` → `P.A. Bolzano`,
  `Trento` → `P.A. Trento`, `Emilia Romagna` → `Emilia-Romagna`,
  `Friuli Venezia Giulia` → `Friuli-Venezia Giulia`,
  `Valle d'Aosta/Vallée d'Aoste` → `Valle d'Aosta`.
- Aggregati `N.D.` e `Totale` esclusi dai dati COB.

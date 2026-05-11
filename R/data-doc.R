# =============================================================================
# Documentazione roxygen2 dei tre dataset canonici GOL
# -----------------------------------------------------------------------------
# Placeholder pronto per `devtools::document()` quando il package verra'
# inizializzato. I file `.rda` generati da `build_gol_datasets()` saranno
# accessibili tramite `data(<nome>)` e descritti dalle help page sottostanti.
# =============================================================================

#' Serie INAPP Focus GOL mensile (2024-06 -> 2025-12)
#'
#' Long format dei 12 report INAPP Focus GOL, ciascuno con quattro tavole
#' regionali (1.1, 1.2, 2.1, 2.2/3.1). Estratto da
#' `INAPP GOL/csv_long/tab_long_completo.csv`, prodotto dall'estrattore
#' Python `estrai_tavole_inapp_gol.py`.
#'
#' @format Un `data.table` con le seguenti colonne:
#' \describe{
#'   \item{report_id}{Identificativo del report sorgente (UUID o nome file).}
#'   \item{data_riferimento}{`IDate`, data di riferimento dei dati.}
#'   \item{tavola}{Numero della tavola (1.1, 1.2, 2.1, 2.2).}
#'   \item{titolo_tabella}{Titolo completo della tabella nel PDF.}
#'   \item{dimensione}{`"regione"` o `"percorso"`.}
#'   \item{etichetta}{Valore della dimensione (22 etichette regionali
#'     canoniche, o nome del percorso).}
#'   \item{variabile}{Nome semantico della variabile (es. `"raggiunti"`,
#'     `"con_politica"`, `"occupati_totale"`, `"incidenza_pc"`).}
#'   \item{percorso}{Solo per tavola 2.2: uno dei 5 percorsi GOL; vuoto
#'     altrove.}
#'   \item{unita_misura}{`"valore_assoluto"`, `"percentuale"` o
#'     `"percentuale_riga"`.}
#'   \item{valore}{Valore numerico parsato.}
#' }
#'
#' @source INAPP, Note di monitoraggio "Focus GOL", 2024-2025.
#'   Estrazione automatica via Poppler (`pdftotext`) + parser Python custom.
#'
#' @seealso `verifica_coerenza.md` per i controlli di consistenza
#'   inter-tavola.
"gol_inapp_mensile"

#' Storico GOL regionale 2022-2025 (temi A1, B, F, H)
#'
#' Unione dei quattro file `gol_{A1,B,F,H}_long.csv` di `dataset_long/`,
#' ristretta alle righe con `quality_flag == "ok"` e ad anchor regionale
#' canonico (22 etichette). Copre 27 report di monitoraggio ANPAL / MLPS /
#' INAPP dal 2022-09 al 2025-12.
#'
#' La decodifica semantica di `col_index` non e' inclusa: per ricostruire
#' il significato di ogni colonna usare `caption_title` + `header_above`,
#' tenendo conto di tre rotture di serie documentate
#' (`dataset_long/README.md`):
#' \enumerate{
#'   \item Cambio unita' (presi in carico -> individui) nel 2025.
#'   \item Cambio regola di assegnazione regionale (regione di presa in
#'     carico -> regione di ultima presa in carico) nel 2025.
#'   \item Ampliamento 4 -> 5 percorsi GOL nel 2025 (per A1, F, H).
#' }
#'
#' @format Un `data.table` con le colonne originali del long format
#'   (`file`, `ente`, `data_riferimento`, `tema`, `caption_num`,
#'   `caption_title`, `page`, `anchor`, `col_index`, `header_above`,
#'   `valore_raw`, `valore_num`, `unit_guess`, `quality_flag`).
#'
#' @source ANPAL, MLPS, INAPP — Note di monitoraggio Programma GOL,
#'   2022-2025. Estrazione automatica da PDF.
"gol_storico_regionale"

#' Comunicazioni Obbligatorie regionali trimestrali (2017-Q1 -> 2025-Q3)
#'
#' Flussi di avviamenti e cessazioni dei rapporti di lavoro per Regione e
#' trimestre, estratti dagli allegati statistici INPS "Allegato-IV-
#' Trimestre". Nomi regionali armonizzati alle 21 etichette canoniche GOL;
#' marker `N.D.` e `Totale` sono esclusi.
#'
#' Utile come baseline esogena per studi di impatto del Programma GOL sul
#' mercato del lavoro locale.
#'
#' @format Un `data.table` con le seguenti colonne:
#' \describe{
#'   \item{regione}{Etichetta regionale canonica (21 valori).}
#'   \item{anno}{Anno (2017-2025).}
#'   \item{trimestre}{Trimestre (1-4).}
#'   \item{trimestre_roman}{Trimestre in numeri romani (I-IV).}
#'   \item{flusso}{`"avviamenti"` o `"cessazioni"`.}
#'   \item{rapporti}{Numero di rapporti di lavoro avviati / cessati.}
#'   \item{lavoratori}{Numero di lavoratori distinti coinvolti.}
#'   \item{media}{Rapporti per lavoratore (rapporti / lavoratori).}
#'   \item{file_origine}{Nome del file XLSX di origine.}
#'   \item{data_inizio_trimestre}{`IDate`, primo giorno del trimestre, per
#'     facilitare il merge con serie mensili.}
#' }
#'
#' @source INPS, "Allegato IV - Trimestre" delle Comunicazioni Obbligatorie,
#'   2017-2025.
"cob_regionale_trimestrale"

#' Rotture di metodo nella serie GOL
#'
#' Tre eventi documentati di discontinuita' metodologica nei dati GOL, tutti
#' collocati al passaggio dal formato pre-2025 (ANPAL/MLPS) al formato INAPP
#' Focus GOL del 2025. Pensato per essere passato come parametro `ruptures`
#' a [plot_timeline()].
#'
#' @format Un `data.table` con 3 righe e le colonne:
#' \describe{
#'   \item{data}{`IDate`, data convenzionale della rottura (2025-01-01).}
#'   \item{evento}{Descrizione sintetica dell'evento.}
#'   \item{scope}{Ambito interessato (quali temi / quali colonne).}
#'   \item{riferimento}{Documento di riferimento.}
#' }
#'
#' @source `dataset_long/README.md`, sezione "Cambiamenti di definizione
#'   lungo la serie".
"gol_method_ruptures"

#' Raccomandazioni di rescanning per le estrazioni storiche GOL
#'
#' Snapshot del risultato di [gol_storico_quality()] al momento della build
#' di `gol_storico_regionale`, filtrato a `severity != "ok"`. Identifica i
#' PDF di origine la cui estrazione in `dataset_long/` e' incompleta o
#' rumorosa e che dovrebbero essere ri-estratti dal PDF originale (o
#' sostituiti da una fonte alternativa, come gia' fatto per INAPP A1/1.2).
#'
#' @format Un `data.table` con una riga per `(file, tema, caption_num)`
#'   problematico. Colonne come da output di [gol_storico_quality()].
#'
#' @seealso [gol_storico_quality()], [gol_quality_classify()].
"gol_rescan_recommendations"

#' Decoder semantico per `gol_storico_regionale`
#'
#' Mappa `(tema, caption_num, col_index, era)` alla relativa semantica
#' (`variabile`, `caratteristica`, `modalita`, `percorso`, `unita`,
#' `confidenza`). Costruito via `data-raw/build_storico_decoder.R` con
#' regex auto-derivate da `header_above` modale + `caption_title` modale.
#' E' editabile manualmente via `inst/extdata/storico_decoder.csv`.
#'
#' @format Un `data.table` con circa 230 righe e 15 colonne.
#' @seealso [gol_decode_storico()].
"storico_decoder"

#' Storia lunga GOL: presi in carico 2022-2025
#'
#' Serie regionale dei volumi presi in carico dal Programma GOL, integrata
#' fra storico ANPAL/MLPS (2022-2024) e INAPP mensile (2024-06/2025-12).
#'
#' @format Un `data.table` long con colonne: `data_riferimento, fonte,
#'   regione, percorso, variabile, unita, valore, confidenza, era,
#'   rescan_severity`.
#' @seealso [gol_storia_volumi_series()], [plot_timeline()].
"gol_storia_volumi"

#' Storia lunga GOL: caratteristiche dei beneficiari 2022-2025
#'
#' Serie regionale dei beneficiari per caratteristiche anagrafiche
#' (genere, classe eta', cittadinanza, durata disoccupazione).
#'
#' @format Un `data.table` long con colonne: `data_riferimento, fonte,
#'   regione, percorso, caratteristica, modalita, variabile, unita,
#'   valore, confidenza, era, rescan_severity`.
#' @seealso [gol_storia_caratteristiche_series()].
"gol_storia_caratteristiche"

#' Storia lunga GOL: esiti 2022-2025
#'
#' Serie regionale degli esiti del programma: politiche attivate
#' (tema F), occupazione a 60/90/180 giorni (tema H), LEP e formazione
#' (INAPP tav 2.1), occupati totali e per percorso (INAPP tav 2.2).
#'
#' @format Un `data.table` long con colonne: `data_riferimento, fonte,
#'   regione, percorso, variabile, unita, valore, confidenza,
#'   tema_storico, era, rescan_severity`.
#' @seealso [gol_storia_esiti_series()].
"gol_storia_esiti"

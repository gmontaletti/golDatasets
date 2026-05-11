#!/usr/bin/env python3
# =============================================================================
# Estrazione di tutte le tabelle dal solo report INAPP_Focus-GOL_17-2025
# (dati al 31/12/2025). Per ciascuna tabella produce due file:
#
#   <numero>_<slug>.csv       struttura tabellare ricostruita con tabula
#   <numero>_<slug>.txt       blocco di testo layout-preserving (controllo)
#
# Schema dei file CSV: il contenuto è il dump grezzo di tabula in modalità
# stream, dopo rimozione delle righe completamente vuote. Le intestazioni
# multi-riga restano come righe del CSV: la struttura non è normalizzata
# perché ogni tabella ha layout diverso.
# =============================================================================
from __future__ import annotations

import argparse
import csv
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

import pandas as pd
import tabula


# ---- 1. Inventario delle tabelle del report 17/2025 ------------------------

@dataclass
class TabellaTarget:
    numero: str        # "1.3"
    slug: str          # "individui_caratteristiche_socio_anagrafiche_va"
    pagine: List[int]  # 1-based
    titolo: str        # descrizione sintetica


TARGETS: List[TabellaTarget] = [
    TabellaTarget("1.3",  "caratteristiche_socio_anagrafiche_va",
                  [9, 10],
                  "Individui per Regione e caratteristiche socio-anagrafiche, v.a."),
    TabellaTarget("1.4",  "caratteristiche_socio_anagrafiche_pc",
                  [11, 12],
                  "Individui per Regione e caratteristiche socio-anagrafiche, val.%"),
    TabellaTarget("1.5",  "vulnerabilita_e_percorso",
                  [12, 13, 14],
                  "Individui con caratteristiche di vulnerabilità per percorso"),
    TabellaTarget("1.6",  "patto_servizio_attivo_target_regione",
                  [14, 15],
                  "Individui con patto di servizio attivo per target e regione"),
    TabellaTarget("1.7",  "patto_servizio_composizione_target",
                  [16, 17],
                  "Composizione presi in carico con patto di servizio per target"),
    TabellaTarget("2.2",  "formazione_per_caratteristiche",
                  [20, 21],
                  "Prese in carico e corsi di formazione per area, percorso, età, genere, titolo"),
    TabellaTarget("2.3",  "formazione_competenze_digitali",
                  [22, 23],
                  "Corsi di formazione per arricchimento competenze digitali"),
    TabellaTarget("2.4",  "avvii_corsi_per_anno_area",
                  [24, 25],
                  "Distribuzione avvii corsi di formazione per anno e area geografica"),
    TabellaTarget("2.5",  "durata_corsi_statistiche",
                  [27, 28],
                  "Durata corsi di formazione: media, mediana, quartili"),
    TabellaTarget("2.6",  "durata_corsi_competenze_digitali",
                  [28, 29],
                  "Durata corsi di formazione in competenze digitali"),
    TabellaTarget("2.7",  "tirocini_extracurriculari_avviati",
                  [30, 31],
                  "Tirocini extracurriculari avviati dopo la presa in carico"),
    TabellaTarget("2.8",  "tirocini_stato_31_12_2025",
                  [32, 33],
                  "Tirocini extracurriculari: stato al 31/12/2025"),
    TabellaTarget("2.9",  "tirocini_durata_giorni",
                  [33, 34],
                  "Tirocini extracurriculari terminati: durata effettiva in giorni"),
    TabellaTarget("2.10", "tirocini_per_regione_cpi",
                  [34, 35, 36],
                  "Tirocini extracurriculari avviati totali e promossi dai CPI per regione"),
    TabellaTarget("3.1",  "occupati_per_regione_e_percorso",
                  [37, 38],
                  "Individui occupati alla data di riferimento per regione di presa in carico e percorso"),
    TabellaTarget("3.2",  "occupati_per_tipo_contratto_percorso",
                  [38, 39],
                  "Individui occupati per tipo di contratto e percorso"),
    TabellaTarget("3.3",  "esiti_un_anno_area_geografica",
                  [39, 40],
                  "Esiti occupazionali a un anno per area geografica"),
    TabellaTarget("3.4",  "esiti_un_anno_area_percorso",
                  [41, 42],
                  "Esiti occupazionali a un anno per area geografica e percorso"),
    TabellaTarget("3.5",  "esiti_sei_mesi_post_pal",
                  [43, 44],
                  "Esiti occupazionali nei 6 mesi dalla conclusione della PAL"),
]


# ---- 2. Utility -------------------------------------------------------------

def normalizza_apostrofo(testo: str) -> str:
    return testo.replace("’", "'").replace("`", "'")


def estrai_blocco_testo(pdf: Path, pagine: List[int],
                         numero_tab: str) -> str:
    """Estrae il blocco testuale tra `Tabella <numero>` e la prima fra:
    - `Fonte: ...`
    - `Tabella <numero+1>`
    - `Figura ...`."""
    exe = shutil.which("pdftotext")
    if not exe:
        raise RuntimeError("pdftotext non disponibile")
    primo, ultimo = pagine[0], pagine[-1]
    res = subprocess.run(
        [exe, "-layout", "-enc", "UTF-8",
         "-f", str(primo), "-l", str(ultimo), str(pdf), "-"],
        check=True, capture_output=True, text=True, encoding="utf-8",
    )
    testo = normalizza_apostrofo(res.stdout)
    # taglio dall'inizio del titolo della tabella
    rx_inizio = re.compile(rf"^\s*Tabella\s+{re.escape(numero_tab)}\b",
                            re.MULTILINE)
    m = rx_inizio.search(testo)
    if m:
        testo = testo[m.start():]
    # taglio alla prima occorrenza di un terminatore
    rx_fine = re.compile(
        r"\nFonte\s*:\s*elaborazioni|\n\s*Tabella\s+\d+\.\d+\b|"
        r"\n\s*Figura\s+\d+\.\d+\b",
        re.IGNORECASE,
    )
    m_fine = rx_fine.search(testo)
    if m_fine:
        # includiamo la riga `Fonte:` ma fermiamoci prima del successivo blocco
        if "Fonte" in testo[m_fine.start():m_fine.start() + 12]:
            riga_fine = testo.find("\n", m_fine.end())
            if riga_fine > 0:
                testo = testo[:riga_fine + 1]
            else:
                testo = testo[:m_fine.end()]
        else:
            testo = testo[:m_fine.start()]
    return testo.rstrip() + "\n"


def estrai_tabella_tabula(pdf: Path, pagine: List[int]) -> Optional[pd.DataFrame]:
    """Usa tabula in modalità stream sulle pagine indicate. Restituisce la
    tabella più ampia (per numero di celle) tra quelle individuate, oppure
    None se non viene trovato nulla."""
    pages_str = ",".join(str(p) for p in pagine)
    try:
        dfs = tabula.read_pdf(
            str(pdf), pages=pages_str,
            lattice=False, stream=True, multiple_tables=True,
            pandas_options={"dtype": str},
        )
    except Exception as e:  # pragma: no cover
        print(f"  tabula errore: {e}", file=sys.stderr)
        return None
    if not dfs:
        return None
    # scegliamo quella con il maggior numero di celle valorizzate
    def cellule_non_vuote(df: pd.DataFrame) -> int:
        if df is None or df.empty:
            return 0
        return int(df.notna().sum().sum())
    df = max(dfs, key=cellule_non_vuote)
    # rimuovi righe completamente vuote
    df = df.dropna(how="all").reset_index(drop=True)
    # rimuovi colonne completamente vuote
    df = df.loc[:, df.notna().any()]
    # se le colonne sono "Unnamed: N" sostituiamo con un nome generico
    df.columns = [
        f"c{i+1}" if str(c).startswith("Unnamed") else str(c)
        for i, c in enumerate(df.columns)
    ]
    return df


# ---- 3. Pipeline -----------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", required=True, type=Path,
                    help="Percorso del PDF INAPP_Focus-GOL_17-2025")
    ap.add_argument("--output-dir", required=True, type=Path,
                    help="Cartella di destinazione")
    args = ap.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    indice: List[dict] = []
    for t in TARGETS:
        prefix = f"tab_{t.numero.replace('.', '_')}_{t.slug}"
        path_csv = args.output_dir / f"{prefix}.csv"
        path_txt = args.output_dir / f"{prefix}.txt"
        print(f"--- Tabella {t.numero}: {t.titolo}", file=sys.stderr)

        # 1) testo layout-preserving (sempre disponibile)
        try:
            blocco = estrai_blocco_testo(args.pdf, t.pagine, t.numero)
        except Exception as e:
            blocco = f"ERRORE estrazione testo: {e}\n"
        path_txt.write_text(blocco, encoding="utf-8")

        # 2) struttura via tabula
        df = estrai_tabella_tabula(args.pdf, t.pagine)
        n_righe, n_col = (df.shape if df is not None else (0, 0))
        if df is not None:
            df.to_csv(path_csv, index=False, encoding="utf-8")
        else:
            path_csv.write_text("", encoding="utf-8")

        indice.append({
            "numero": t.numero,
            "titolo": t.titolo,
            "pagine": ",".join(str(p) for p in t.pagine),
            "csv": path_csv.name,
            "txt": path_txt.name,
            "n_righe": n_righe,
            "n_colonne": n_col,
        })

    # indice riepilogativo
    idx_path = args.output_dir / "_indice_tabelle.csv"
    with idx_path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(
            fh,
            fieldnames=["numero", "titolo", "pagine",
                        "csv", "txt", "n_righe", "n_colonne"],
        )
        w.writeheader()
        for r in indice:
            w.writerow(r)

    print(f"\nOutput in: {args.output_dir.resolve()}")
    print("Riepilogo:")
    for r in indice:
        print(f"  Tab {r['numero']:>4}  pagine {r['pagine']:>10}  "
              f"{r['n_righe']:>3} righe x {r['n_colonne']:>2} col")
    return 0


if __name__ == "__main__":
    sys.exit(main())

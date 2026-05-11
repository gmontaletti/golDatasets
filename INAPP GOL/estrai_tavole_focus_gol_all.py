#!/usr/bin/env python3
# =============================================================================
# Estrazione di tutte le tabelle "Tabella X.Y" da TUTTI i report INAPP Focus
# GOL presenti in una directory (estende `estrai_tavole_focus_gol_17.py`).
#
# Strategia: per ogni PDF
#   1. legge il testo con `pdftotext -layout` mantenendo i separatori di pagina
#   2. trova tutte le occorrenze "Tabella X.Y <titolo>" via regex (la prima
#      occorrenza per ogni numero - le successive sono riferimenti)
#   3. estrae la tabella con `tabula` in modalita' stream sulla pagina
#      individuata + le 2 pagine successive (per tabelle multi-pagina)
#   4. salva in <output-dir>/<report_id>/tab_X_Y_<slug>.csv +
#      il blocco testuale .txt per controllo
#   5. produce un indice cumulativo `_indice_tabelle.csv`
#
# Output (esempio):
#   focus_gol_all/
#   ├── INAPP_Focus-GOL_17-2025/
#   │   ├── tab_1_1_*.csv
#   │   ├── tab_1_1_*.txt
#   │   └── ...
#   ├── INAPP_Focus-GOL_16-2025/
#   │   └── ...
#   └── _indice_tabelle.csv         # tutte le tabelle di tutti i report
# =============================================================================
from __future__ import annotations

import argparse
import csv
import re
import shutil
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import pandas as pd

try:
    import tabula  # type: ignore
except ImportError:  # pragma: no cover
    tabula = None

try:
    import pdfplumber  # type: ignore
except ImportError:  # pragma: no cover
    pdfplumber = None


# ---- 1. Regex e mapping ----------------------------------------------------

# Riconosce sia "Tabella 1.1 Programma GOL: ..." sia varianti con trattino
# o virgole. Il numero deve essere all'inizio di riga (titolo, non
# riferimento nel testo).
RX_TABELLA_TITOLO = re.compile(
    r"^\s*Tabella\s+(\d+\.\d+)\s*[-–:]?\s*(.+?)$",
    re.MULTILINE,
)

# Marker di fine tabella (riprende dal parser singolo)
RX_FINE_BLOCCO = re.compile(
    r"\n\s*Fonte\s*:|"
    r"\n\s*Tabella\s+\d+\.\d+\b|"
    r"\n\s*Figura\s+\d+\.\d+\b|"
    r"\n\s*Grafico\s+\d+\.\d+\b",
    re.IGNORECASE,
)


# ---- 2. Utility ------------------------------------------------------------

def normalizza_apostrofo(testo: str) -> str:
    return testo.replace("’", "'").replace("`", "'")


def slugify(titolo: str, max_len: int = 60) -> str:
    """Riduce un titolo a uno slug compatibile con i filename."""
    # Rimuovi accenti
    nfkd = unicodedata.normalize("NFKD", titolo)
    s = "".join(c for c in nfkd if not unicodedata.combining(c))
    s = s.lower()
    s = re.sub(r"[^a-z0-9\s_-]", " ", s)
    s = re.sub(r"\s+", "_", s.strip())
    s = re.sub(r"_+", "_", s)
    return s[:max_len].rstrip("_")


def pdftotext_pages(pdf: Path) -> List[Tuple[int, str]]:
    """Legge il PDF con pdftotext e ritorna lista (n_pagina, testo)."""
    exe = shutil.which("pdftotext")
    if not exe:
        raise RuntimeError("pdftotext (Poppler) non disponibile sul PATH")
    res = subprocess.run(
        [exe, "-layout", "-enc", "UTF-8", str(pdf), "-"],
        check=True, capture_output=True, text=True, encoding="utf-8",
    )
    testo = normalizza_apostrofo(res.stdout)
    # pdftotext separa le pagine con \f (form feed)
    pagine = testo.split("\f")
    return [(i + 1, p) for i, p in enumerate(pagine)]


def trova_tabelle(pagine: List[Tuple[int, str]]) -> Dict[str, Tuple[int, str]]:
    """Per ogni numero di tabella trovato (prima occorrenza vincente),
    ritorna `{numero: (pagina, titolo)}`."""
    out: Dict[str, Tuple[int, str]] = {}
    for pnum, testo in pagine:
        for m in RX_TABELLA_TITOLO.finditer(testo):
            numero = m.group(1)
            titolo = m.group(2).strip()
            # Filtra riferimenti spuri (titolo troppo corto o solo numero)
            if len(titolo) < 8:
                continue
            if numero in out:
                continue
            out[numero] = (pnum, titolo)
    return out


def estrai_blocco_testo(pagine: List[Tuple[int, str]],
                        numero: str, start_page: int,
                        finestra: int = 4) -> str:
    """Restituisce il blocco testuale dalla pagina `start_page` per
    massimo `finestra` pagine, tagliato al primo terminatore."""
    end = min(start_page + finestra, len(pagine))
    blocco_pagine = [t for p, t in pagine if start_page <= p <= end]
    blocco = "\f".join(blocco_pagine)
    rx_inizio = re.compile(
        rf"\bTabella\s+{re.escape(numero)}\b", re.MULTILINE
    )
    m = rx_inizio.search(blocco)
    if m:
        blocco = blocco[m.start():]
    # Tronca alla prossima Tabella/Figura/Fonte
    m_fine = RX_FINE_BLOCCO.search(blocco, pos=10)
    if m_fine:
        if "Fonte" in blocco[m_fine.start():m_fine.start() + 12]:
            riga_fine = blocco.find("\n", m_fine.end())
            if riga_fine > 0:
                blocco = blocco[:riga_fine + 1]
            else:
                blocco = blocco[:m_fine.end()]
        else:
            blocco = blocco[:m_fine.start()]
    return blocco.rstrip() + "\n"


def _normalize_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.dropna(how="all").reset_index(drop=True)
    df = df.loc[:, df.notna().any()]
    df.columns = [
        f"c{i+1}" if str(c).startswith("Unnamed") or not str(c).strip()
        else str(c)
        for i, c in enumerate(df.columns)
    ]
    return df


def _cells(df: pd.DataFrame) -> int:
    return int(df.notna().sum().sum()) if not df.empty else 0


def estrai_tabella_tabula(pdf: Path, start_page: int,
                          finestra: int = 3) -> Optional[pd.DataFrame]:
    """Backend tabula (richiede Java). Ritorna None se Java non disponibile."""
    if tabula is None:
        return None
    pages_str = ",".join(str(p) for p in range(start_page,
                                                start_page + finestra))
    try:
        dfs = tabula.read_pdf(
            str(pdf), pages=pages_str,
            lattice=False, stream=True, multiple_tables=True,
            pandas_options={"dtype": str},
        )
    except Exception:  # pragma: no cover
        return None
    if not dfs:
        return None
    return _normalize_df(max(dfs, key=_cells))


def estrai_tabella_pdfplumber(pdf: Path, start_page: int,
                              finestra: int = 3) -> Optional[pd.DataFrame]:
    """Backend pdfplumber (puro Python, fallback)."""
    if pdfplumber is None:
        return None
    raccolta: List[pd.DataFrame] = []
    try:
        with pdfplumber.open(str(pdf)) as plumber:
            n_pag = len(plumber.pages)
            for p in range(start_page, min(start_page + finestra, n_pag + 1)):
                page = plumber.pages[p - 1]
                tables = page.extract_tables() or []
                for t in tables:
                    if not t:
                        continue
                    df = pd.DataFrame(t)
                    # promuove la prima riga se sembra header
                    if df.shape[0] > 1:
                        df.columns = [
                            str(c) if c is not None else f"c{i+1}"
                            for i, c in enumerate(df.iloc[0])
                        ]
                        df = df.iloc[1:].reset_index(drop=True)
                    raccolta.append(df)
    except Exception as e:  # pragma: no cover
        print(f"    pdfplumber errore p.{start_page}: {e}", file=sys.stderr)
        return None
    if not raccolta:
        return None
    return _normalize_df(max(raccolta, key=_cells))


def estrai_tabella(pdf: Path, start_page: int,
                   finestra: int = 3) -> Tuple[Optional[pd.DataFrame], str]:
    """Prova tabula, poi pdfplumber. Ritorna (df, backend_usato)."""
    df = estrai_tabella_tabula(pdf, start_page, finestra)
    if df is not None and not df.empty:
        return df, "tabula"
    df = estrai_tabella_pdfplumber(pdf, start_page, finestra)
    if df is not None and not df.empty:
        return df, "pdfplumber"
    return None, "none"


# ---- 3. Pipeline -----------------------------------------------------------

@dataclass
class IndexRow:
    report_id: str
    pdf_path: str
    numero: str
    titolo: str
    slug: str
    pagina: int
    n_righe: int
    n_colonne: int
    note: str = ""


def processa_pdf(pdf: Path, output_dir: Path) -> List[IndexRow]:
    report_id = pdf.stem
    rep_dir = output_dir / report_id
    rep_dir.mkdir(parents=True, exist_ok=True)

    pagine = pdftotext_pages(pdf)
    tabelle = trova_tabelle(pagine)
    print(f"  {report_id}: {len(tabelle)} tabelle individuate "
          f"({len(pagine)} pp)")

    righe: List[IndexRow] = []
    for numero in sorted(tabelle.keys(), key=lambda s: tuple(
            int(x) for x in s.split("."))):
        start_page, titolo = tabelle[numero]
        slug = slugify(titolo)

        # blocco testuale
        blocco = estrai_blocco_testo(pagine, numero, start_page)
        prefix = f"tab_{numero.replace('.', '_')}_{slug}"
        (rep_dir / f"{prefix}.txt").write_text(blocco, encoding="utf-8")

        # tabella (tabula primario, pdfplumber fallback)
        df, backend = estrai_tabella(pdf, start_page)
        n_r = n_c = 0
        note = ""
        if df is not None and not df.empty:
            n_r, n_c = df.shape
            df.to_csv(rep_dir / f"{prefix}.csv", index=False)
            note = f"backend={backend}"
        else:
            note = "tabella_non_estratta"

        righe.append(IndexRow(
            report_id=report_id, pdf_path=str(pdf), numero=numero,
            titolo=titolo, slug=slug, pagina=start_page,
            n_righe=n_r, n_colonne=n_c, note=note,
        ))
    return righe


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Estrazione tabelle INAPP Focus GOL multi-report"
    )
    ap.add_argument("--input-dir", required=True, type=Path,
                    help="Cartella contenente i PDF (es. timeline_gol/2025)")
    ap.add_argument("--output-dir", required=True, type=Path,
                    help="Cartella di destinazione")
    ap.add_argument("--pattern", default="INAPP_Focus-GOL*-2025.pdf",
                    help="Glob dei PDF da processare")
    args = ap.parse_args()

    if tabula is None and pdfplumber is None:
        print("ERRORE: serve almeno uno tra tabula-py e pdfplumber "
              "(pip install tabula-py pdfplumber)",
              file=sys.stderr)
        return 1

    args.output_dir.mkdir(parents=True, exist_ok=True)

    pdfs = sorted(args.input_dir.glob(args.pattern))
    if not pdfs:
        print(f"Nessun PDF trovato in {args.input_dir} con pattern "
              f"'{args.pattern}'", file=sys.stderr)
        return 2

    print(f"Trovati {len(pdfs)} PDF da processare\n")

    tutti: List[IndexRow] = []
    for pdf in pdfs:
        tutti.extend(processa_pdf(pdf, args.output_dir))

    # Indice CSV cumulativo
    idx_path = args.output_dir / "_indice_tabelle.csv"
    with idx_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["report_id", "numero", "titolo", "slug", "pagina",
                    "n_righe", "n_colonne", "note", "pdf_path"])
        for r in tutti:
            w.writerow([r.report_id, r.numero, r.titolo, r.slug,
                        r.pagina, r.n_righe, r.n_colonne, r.note, r.pdf_path])

    print(f"\nIndice salvato: {idx_path}")
    print(f"Totale tabelle estratte: {len(tutti)} "
          f"(media {len(tutti) / len(pdfs):.1f} per report)")
    print(f"Estrazioni vuote: "
          f"{sum(1 for r in tutti if r.note == 'tabella_non_estratta')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

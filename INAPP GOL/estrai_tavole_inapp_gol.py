#!/usr/bin/env python3
# =============================================================================
# Estrazione tavole regionali dalle Note di monitoraggio "Inapp Focus GOL"
# -----------------------------------------------------------------------------
# Versione Python del parser. Migliorata rispetto allo script R per gestire:
#   - varianti del numero di colonne in Tavola 1.1 (3 o 4 anni di osservazione)
#   - forme abbreviate ed eterogenee dei nomi regionali (es. FVG)
#   - varianti tipografiche dell'apostrofo (d', D', U+2019)
#   - tabella 2.2 ridenominata 3.1 nei report del 31/12/2025
#   - numeri privi del separatore delle migliaia
#   - file PDF con nomi non standard (es. UUID anziché INAPP_FocusGOL_*)
#
# Output (in --output-dir):
#   tab_1_1_long.csv            Tavola 1.1 in formato lungo
#   tab_1_2_long.csv            Tavola 1.2 in formato lungo
#   tab_2_1_long.csv            Tavola 2.1 in formato lungo
#   tab_2_2_long.csv            Tavola 2.2/3.1 in formato lungo
#   tab_long_completo.csv       unione delle quattro in un'unica griglia
#   tab_*_wide.csv              versioni wide per controllo manuale
#   diagnostica.csv             copertura righe per report e tavola
#
# Schema CSV unificato:
#   data_riferimento | report_id | tavola | dimensione | etichetta |
#   variabile | percorso | unita_misura | valore
# =============================================================================
from __future__ import annotations

import argparse
import csv
import re
import shutil
import subprocess
import sys
import unicodedata
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Iterable, List, Optional

# pdftotext (Poppler) è il backend principale: produce un layout fisso che
# semplifica il riconoscimento delle righe nelle tabelle a larghezza variabile.
# pdfplumber è il fallback puro Python qualora pdftotext non sia disponibile.
try:
    import pdfplumber  # type: ignore
except ImportError:  # pragma: no cover
    pdfplumber = None

# ---- 1. Configurazione costante --------------------------------------------

REGIONI_CANONICHE: List[str] = [
    "Abruzzo", "Basilicata", "P.A. Bolzano", "Calabria", "Campania",
    "Emilia-Romagna", "Friuli-Venezia Giulia", "Lazio", "Liguria",
    "Lombardia", "Marche", "Molise", "Piemonte", "Puglia", "Sardegna",
    "Sicilia", "Toscana", "P.A. Trento", "Umbria", "Valle d'Aosta",
    "Veneto", "Totale",
]

# Pattern regex per riconoscere ciascuna regione a inizio riga.
# Le forme abbreviate ricorrenti (FVG) sono incluse come alternativa.
REGIONI_PATTERN: dict[str, str] = {
    "Abruzzo":              r"Abruzzo",
    "Basilicata":           r"Basilicata",
    "P.A. Bolzano":         r"(?:P\.?\s*A\.?\s*)?Bolzano",
    "Calabria":             r"Calabria",
    "Campania":             r"Campania",
    "Emilia-Romagna":       r"Emilia[\-\s]Romagna",
    "Friuli-Venezia Giulia": r"(?:Friuli[\-\s]Venezia\s+Giulia|FVG)",
    "Lazio":                r"Lazio",
    "Liguria":              r"Liguria",
    "Lombardia":            r"Lombardia",
    "Marche":               r"Marche",
    "Molise":               r"Molise",
    "Piemonte":             r"Piemonte",
    "Puglia":               r"Puglia",
    "Sardegna":             r"Sardegna",
    "Sicilia":              r"Sicilia",
    "Toscana":              r"Toscana",
    "P.A. Trento":          r"(?:P\.?\s*A\.?\s*)?Trento",
    "Umbria":               r"Umbria",
    "Valle d'Aosta":        r"Valle\s*[dD][’'`]\s*Aosta",
    "Veneto":               r"Veneto",
    "Totale":               r"Totale",
}

PERCORSI_CANONICI: List[str] = [
    "1_reinserimento_lavorativo",
    "2_aggiornamento_upskilling",
    "3_riqualificazione_reskilling",
    "4_lavoro_inclusione",
]

PERCORSI_PATTERN: dict[str, str] = {
    "1_reinserimento_lavorativo":
        r"1\s*[\.\)\-]?\s*Reinserimento\s+lavorativo",
    "2_aggiornamento_upskilling":
        r"2\s*[\.\)\-]?\s*(?:Aggiornamento|Upskilling)",
    "3_riqualificazione_reskilling":
        r"3\s*[\.\)\-]?\s*(?:Riqualificazione|Reskilling)",
    "4_lavoro_inclusione":
        r"4\s*[\.\)\-]?\s*Lavoro\s+e\s+inclusione",
}

MESI_IT = {
    "gennaio": 1, "febbraio": 2, "marzo": 3, "aprile": 4, "maggio": 5,
    "giugno": 6, "luglio": 7, "agosto": 8, "settembre": 9, "ottobre": 10,
    "novembre": 11, "dicembre": 12,
}

# Numero italiano: 1.234.567,89  oppure  1234567,89  oppure  18,7
NUM_TOKEN = r"-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?"

# ---- 2. Utility -------------------------------------------------------------

def parse_num_it(token: str) -> Optional[float]:
    if token is None:
        return None
    t = token.strip()
    if t in ("", "-", "n.d.", "n/d", "nd"):
        return None
    # rimuove i separatori delle migliaia, sostituisce la virgola decimale
    t = t.replace(".", "").replace(",", ".")
    try:
        return float(t)
    except ValueError:
        return None


def normalizza_apostrofo(testo: str) -> str:
    """Sostituisce le varianti tipografiche dell'apostrofo con la forma ASCII."""
    return testo.replace("’", "'").replace("`", "'")


# ---- 2.1 Pre-elaborazione delle righe -------------------------------------

# Pattern delle regioni in versione "spaziata" (cioè con spazi facoltativi
# tra i caratteri), per recuperare le righe in cui pdftotext fraziona il
# testo (es. "Ba s i l i ca ta" anziché "Basilicata"). Il pattern viene
# costruito intercalando "\s*" tra i caratteri non spazio del nome canonico.

def _spaced_pattern(nome: str) -> str:
    parti = []
    for c in nome:
        if c == " ":
            parti.append(r"\s+")
        elif c == ".":
            parti.append(r"\.")
        elif c == "-":
            parti.append(r"[\-\s]")
        elif c == "'":
            parti.append(r"['’`]")
        else:
            parti.append(re.escape(c))
    return r"\s*".join(parti)


REGIONI_PATTERN_SPAZIATO = {
    nome: re.compile(_spaced_pattern(nome), re.IGNORECASE)
    for nome in REGIONI_CANONICHE
}

# Coppie di anchor per ricomporre nomi spezzati su due righe.
SPLIT_ANCHORS = [
    ("Friuli-Venezia", "Giulia"),
    ("Emilia-", "Romagna"),
    ("Emilia", "Romagna"),
    ("Valle", "d'Aosta"),
    ("P.A.", "Bolzano"),
    ("P.A.", "Trento"),
]


def canonicalizza_righe(testo: str) -> str:
    """Normalizza il testo di una sezione tabellare:
    1. Ricompone le righe in cui il nome di una regione è andato a capo.
    2. Sostituisce le occorrenze di nomi regionali "spaziati" con la
       forma canonica.
    """
    if not testo:
        return testo
    righe = testo.splitlines()

    # 1. Ricomposizione dei nomi spezzati
    out: List[str] = []
    i = 0
    while i < len(righe):
        r = righe[i]
        prossima = righe[i + 1] if i + 1 < len(righe) else ""
        ricomposta = None
        for prefix, suffix in SPLIT_ANCHORS:
            if r.rstrip().endswith(prefix) and prossima.lstrip().startswith(suffix):
                # ricomponiamo: prefix + " " + resto della riga successiva
                resto = prossima.lstrip()
                ricomposta = r.rstrip() + " " + resto
                break
        if ricomposta is not None:
            out.append(ricomposta)
            i += 2
        else:
            out.append(r)
            i += 1

    # 2. Sostituzione dei nomi regionali con letter-spacing
    risultato: List[str] = []
    for r in out:
        nuova = r
        for nome, rx in REGIONI_PATTERN_SPAZIATO.items():
            m = rx.match(nuova.lstrip())
            if not m:
                continue
            # rispettiamo il leading whitespace della riga originale
            leading_len = len(nuova) - len(nuova.lstrip())
            inizio_match = leading_len
            fine_match = leading_len + m.end()
            nuova = nuova[:inizio_match] + nome + nuova[fine_match:]
            break
        risultato.append(nuova)
    return "\n".join(risultato)


def estrai_data_riferimento(testo: str) -> Optional[date]:
    pat = re.compile(
        r"(?:dati\s+al|stato\s+dell.arte\s+al|al)\s+"
        r"(\d{1,2})\s+(\w+)\s+(\d{4})",
        re.IGNORECASE,
    )
    m = pat.search(testo)
    if not m:
        return None
    giorno = int(m.group(1))
    mese = MESI_IT.get(m.group(2).lower())
    anno = int(m.group(3))
    if mese is None:
        return None
    try:
        return date(anno, mese, giorno)
    except ValueError:
        return None


# ---- 3. Estrazione testo ----------------------------------------------------

@dataclass
class Documento:
    file_path: Path
    pagine: List[str] = field(default_factory=list)

    @property
    def testo(self) -> str:
        return "\n".join(self.pagine)

    @property
    def report_id(self) -> str:
        return self.file_path.stem


def _pdftotext_layout(file_path: Path) -> List[str]:
    """Estrae il testo del PDF preservando il layout, una pagina alla volta."""
    exe = shutil.which("pdftotext")
    if exe is None:
        raise RuntimeError("pdftotext non trovato nel PATH")
    pagine: List[str] = []
    # uso -f / -l per generare una pagina alla volta, evitando il marker \f
    # che pdftotext inserisce di default tra pagine.
    info = subprocess.run(
        [exe, "-layout", "-enc", "UTF-8", str(file_path), "-"],
        check=True, capture_output=True, text=True, encoding="utf-8",
    )
    # pdftotext separa le pagine con form-feed (\x0c)
    for blocco in info.stdout.split("\x0c"):
        pagine.append(normalizza_apostrofo(blocco))
    # rimuoviamo eventuale pagina vuota finale
    while pagine and not pagine[-1].strip():
        pagine.pop()
    return pagine


def _pdfplumber_layout(file_path: Path) -> List[str]:
    if pdfplumber is None:
        raise RuntimeError("pdfplumber non disponibile")
    pagine: List[str] = []
    with pdfplumber.open(str(file_path)) as pdf:
        for p in pdf.pages:
            txt = p.extract_text(layout=True) or ""
            pagine.append(normalizza_apostrofo(txt))
    return pagine


def carica_documento(file_path: Path, backend: str = "auto") -> Documento:
    if backend == "pdftotext" or (backend == "auto" and shutil.which("pdftotext")):
        pagine = _pdftotext_layout(file_path)
    else:
        pagine = _pdfplumber_layout(file_path)
    return Documento(file_path=file_path, pagine=pagine)


def trova_blocco(pagine: List[str], header_pat: str,
                 n_pagine_extra: int = 1) -> str:
    rx = re.compile(header_pat, re.IGNORECASE | re.DOTALL)
    for i, p in enumerate(pagine):
        if rx.search(p):
            fine = min(i + n_pagine_extra + 1, len(pagine))
            return "\n".join(pagine[i:fine])
    return ""


# Etichetta che identifica l'inizio del titolo (es. "Tabella 1.1").
# Il titolo è composto dalla riga iniziale e dalle eventuali continuazioni
# successive che non contengono cifre, fino alla prima riga "tabellare".
def estrai_titolo_tabella(blocco: str, numero_tabella: str) -> str:
    """Estrae il titolo descrittivo della tabella dal blocco di testo.

    Strategia:
    - cerca solo l'occorrenza maiuscola di `Tabella X.Y` a inizio riga
      (le forme `(tabella X.Y)` minuscole nel corpo del testo vengono
      ignorate);
    - prende la prima riga e le sue continuazioni, fermandosi al
      primo segno di intestazione tabellare (linea vuota, riga con
      cifre, riga con marcatori `(A)`/`(B)`, riga con un tab spaziale
      di più di 3 spazi seguiti da etichetta colonna).
    """
    if not blocco:
        return ""
    rx_inizio = re.compile(
        rf"^\s*Tabella\s+{re.escape(numero_tabella)}\b"
    )
    righe = blocco.splitlines()
    inizio = next((i for i, r in enumerate(righe) if rx_inizio.search(r)), None)
    if inizio is None:
        return ""

    # raccogliamo la prima riga e le continuazioni descrittive.
    # Una continuazione è ammessa se NON contiene cifre e NON contiene
    # marcatori di colonna come "(A)"; se contiene un marcatore di fine
    # titolo (v.a./val.%) viene comunque inclusa (è la chiusura del titolo).
    parti: List[str] = [righe[inizio].strip()]
    for r in righe[inizio + 1:inizio + 6]:
        if not r.strip():
            break
        if re.search(r"\d", r) or re.search(r"\([A-Z](?:/[A-Z])?\)", r):
            break
        parti.append(r.strip())
        # se questa continuazione contiene già il marcatore terminale,
        # interrompiamo per evitare di catturare gli header di colonna
        if re.search(r"v\.\s*a\.\s*(?:e\s*v(?:al)?\.\s*%?)?", r,
                     re.IGNORECASE):
            break
    titolo = " ".join(p for p in parti if p)
    titolo = re.sub(r"\s{2,}", " ", titolo).strip()

    # 1. Tronca al primo marcatore terminale ricorrente nei titoli del corpus
    #    ("v.a. e val.%", "v.a. e v. %", "v.a. e v.%", "v.a.").
    rx_fine = re.compile(
        r"(v\.\s*a\.\s*(?:e\s*v(?:al)?\.\s*%?)?)",
        re.IGNORECASE,
    )
    m = rx_fine.search(titolo)
    if m:
        titolo = titolo[: m.end()].rstrip(" ,;:")
        return titolo

    # 2. Fallback: tronca a parole-marker tipiche delle intestazioni di colonna
    #    ricorrenti nelle tabelle 2.x ("Individui con LEP", "Occupati alla
    #    data", "Dettaglio formazione", "Prese in carico per anno").
    stop_markers = [
        r"\bIndividui con LEP\b",
        r"\bOccupati alla data\b",
        r"\bDettaglio formazione\b",
        r"\bPrese in carico per anno\b",
        r"\bRegione presa in carico\b",
        r"\bIndividui presi in carico\b",
        r"\bIndividui raggiunti\b",
    ]
    rx_stop_word = re.compile("|".join(stop_markers), re.IGNORECASE)
    m = rx_stop_word.search(titolo)
    if m:
        titolo = titolo[: m.start()].rstrip(" ,;:")
    return titolo


# ---- 4. Estrazione righe ----------------------------------------------------

def estrai_righe_regionali(testo: str, n_atteso: int) -> List[dict]:
    """Per ogni regione canonica cerca la prima riga che inizia con il nome
    regionale e contiene almeno `n_atteso` token numerici."""
    out: List[dict] = []
    if not testo:
        return out
    righe = [r.strip() for r in testo.splitlines() if r.strip()]
    for nome, pat in REGIONI_PATTERN.items():
        rx = re.compile(rf"^\s*{pat}\s+(.*)$", re.IGNORECASE)
        trovata = None
        for r in righe:
            m = rx.match(r)
            if not m:
                continue
            tail = m.group(1)
            tokens = re.findall(NUM_TOKEN, tail)
            if len(tokens) >= n_atteso:
                # prendiamo gli ultimi n_atteso, perché alcune righe contengono
                # parole iniziali (note, asterischi, etc.)
                tokens = tokens[-n_atteso:]
                valori = [parse_num_it(t) for t in tokens]
                trovata = {"regione": nome}
                for k, v in enumerate(valori, start=1):
                    trovata[f"v{k}"] = v
                break
        if trovata is not None:
            out.append(trovata)
    return out


def estrai_righe_percorso(testo: str, n_atteso: int) -> List[dict]:
    out: List[dict] = []
    if not testo:
        return out
    righe = [r.strip() for r in testo.splitlines() if r.strip()]
    for nome, pat in PERCORSI_PATTERN.items():
        rx = re.compile(rf"^\s*{pat}\s+(.*)$", re.IGNORECASE)
        trovata = None
        for r in righe:
            m = rx.match(r)
            if not m:
                continue
            tail = m.group(1)
            tokens = re.findall(NUM_TOKEN, tail)
            if len(tokens) >= n_atteso:
                tokens = tokens[-n_atteso:]
                valori = [parse_num_it(t) for t in tokens]
                trovata = {"percorso": nome}
                for k, v in enumerate(valori, start=1):
                    trovata[f"v{k}"] = v
                break
        if trovata is not None:
            out.append(trovata)
    return out


# ---- 5. Parser specifici ----------------------------------------------------

def determina_anni_tab_1_1(testo: str) -> List[str]:
    """Inferisce dalla testata gli anni inclusi nella Tavola 1.1.

    Considera solo gli anni 2022-2030 in ordine cronologico crescente,
    a prescindere dall'ordine di apparizione nel testo dell'intestazione."""
    anni = re.findall(r"\b(20[2-3]\d)\b", testo[:1500])
    anni_validi = sorted(set(a for a in anni if 2022 <= int(a) <= 2030))
    return list(anni_validi)


def parse_tab_1_1(testo: str) -> tuple[List[dict], List[str]]:
    anni = determina_anni_tab_1_1(testo)
    n_anni = len(anni)
    if n_anni < 2:
        # fallback: prova con 3 e poi con 4 anni
        for n_anni in (4, 3):
            n_atteso = n_anni + 3  # n anni + totale + incidenza_pc + individui
            righe = estrai_righe_regionali(testo, n_atteso)
            if righe:
                anni = [str(2022 + i) for i in range(n_anni)]
                break
        else:
            return [], []
    n_atteso = n_anni + 3
    righe = estrai_righe_regionali(testo, n_atteso)
    out = []
    for r in righe:
        d = {"regione": r["regione"]}
        for i, anno in enumerate(anni):
            d[anno] = r[f"v{i+1}"]
        d["totale"]       = r[f"v{n_anni+1}"]
        d["incidenza_pc"] = r[f"v{n_anni+2}"]
        d["individui"]    = r[f"v{n_anni+3}"]
        out.append(d)
    return out, anni


def parse_tab_1_2(testo: str) -> List[dict]:
    righe = estrai_righe_regionali(testo, 10)
    nomi = ["perc1_ass", "perc2_ass", "perc3_ass", "perc4_ass", "perc5_ass",
            "perc1_pc", "perc2_pc", "perc3_pc", "perc4_pc", "perc5_pc"]
    return [
        {"regione": r["regione"], **{n: r[f"v{i+1}"] for i, n in enumerate(nomi)}}
        for r in righe
    ]


def parse_tab_2_1(testo: str) -> List[dict]:
    righe = estrai_righe_regionali(testo, 15)
    nomi = [
        "raggiunti", "con_politica", "con_politica_pc",
        "lep_e", "lep_f1", "lep_f2",
        "c07_form_incl_dig", "c11_form_no_dig", "c12_form_spec_dig",
        "lep_h", "lep_j", "lep_o",
        "tirocinio_co", "con_pol_o_tiroc", "con_pol_o_tiroc_pc",
    ]
    return [
        {"regione": r["regione"], **{n: r[f"v{i+1}"] for i, n in enumerate(nomi)}}
        for r in righe
    ]


def parse_tab_2_2(testo: str) -> List[dict]:
    nomi = [
        "presi_in_carico", "occupati_totale", "occupati_pc",
        "nuovi_occupati", "nuovi_occupati_pc",
        "gia_occupati", "gia_occupati_pc",
        "quota_nuovi_su_occ",
    ]
    out: List[dict] = []
    reg = estrai_righe_regionali(testo, 8)
    for r in reg:
        d = {"dimensione": "regione", "etichetta": r["regione"], "percorso": None}
        for i, n in enumerate(nomi):
            d[n] = r[f"v{i+1}"]
        out.append(d)
    per = estrai_righe_percorso(testo, 8)
    for r in per:
        d = {"dimensione": "percorso", "etichetta": r["percorso"],
             "percorso": r["percorso"]}
        for i, n in enumerate(nomi):
            d[n] = r[f"v{i+1}"]
        out.append(d)
    return out


# ---- 6. Pipeline su un singolo PDF -----------------------------------------

@dataclass
class Estrazione:
    report_id: str
    data_riferimento: Optional[date]
    anni_tab_1_1: List[str]
    tab_1_1: List[dict]
    tab_1_2: List[dict]
    tab_2_1: List[dict]
    tab_2_2: List[dict]
    titoli: dict[str, str] = field(default_factory=dict)


def processa_pdf(file_path: Path) -> Estrazione:
    print(f"Elaboro: {file_path.name}", file=sys.stderr)
    doc = carica_documento(file_path)
    data_rif = estrai_data_riferimento(doc.testo)

    # `[\s\-]+` consente sia `Tabella 2.2 Programma GOL` sia
    # `Tabella 2.2 - Programma GOL` (variante 30/06/2024).
    sep = r"[\s\-:]+"
    blocco_11 = trova_blocco(
        doc.pagine,
        rf"Tabella\s+1\.1{sep}Programma\s+GOL.*prese\s+in\s+carico",
    )
    blocco_12 = trova_blocco(
        doc.pagine,
        rf"Tabella\s+1\.2{sep}Programma\s+GOL.*[Rr]egione\s+e\s+percorso",
    )
    blocco_21 = trova_blocco(
        doc.pagine,
        rf"Tabella\s+2\.1{sep}Programma\s+GOL.*almeno\s+una\s+politica",
        n_pagine_extra=1,
    )
    blocco_22 = trova_blocco(
        doc.pagine,
        rf"Tabella\s+2\.2{sep}Programma\s+GOL.*occupati",
        n_pagine_extra=1,
    )
    if not blocco_22:
        blocco_22 = trova_blocco(
            doc.pagine,
            rf"Tabella\s+3\.1{sep}Programma\s+GOL.*occupati",
            n_pagine_extra=1,
        )

    tab11, anni = parse_tab_1_1(canonicalizza_righe(blocco_11))
    tab12 = parse_tab_1_2(canonicalizza_righe(blocco_12))
    tab21 = parse_tab_2_1(canonicalizza_righe(blocco_21))
    tab22 = parse_tab_2_2(canonicalizza_righe(blocco_22))

    # Per la tavola 2.2, in alcuni report il marcatore è "Tabella 3.1": cerchiamo
    # entrambe le forme e scegliamo quella effettivamente presente nel blocco.
    if blocco_22 and re.search(r"Tabella\s+3\.1", blocco_22, re.IGNORECASE):
        num_22 = "3.1"
    else:
        num_22 = "2.2"

    titoli = {
        "1.1": estrai_titolo_tabella(blocco_11, "1.1"),
        "1.2": estrai_titolo_tabella(blocco_12, "1.2"),
        "2.1": estrai_titolo_tabella(blocco_21, "2.1"),
        "2.2": estrai_titolo_tabella(blocco_22, num_22),
    }

    return Estrazione(
        report_id=doc.report_id,
        data_riferimento=data_rif,
        anni_tab_1_1=anni,
        tab_1_1=tab11,
        tab_1_2=tab12,
        tab_2_1=tab21,
        tab_2_2=tab22,
        titoli=titoli,
    )


# ---- 7. Trasformazione in formato lungo ------------------------------------

def to_long_1_1(rec: Estrazione) -> List[dict]:
    out: List[dict] = []
    for r in rec.tab_1_1:
        for var in rec.anni_tab_1_1 + ["totale", "incidenza_pc", "individui"]:
            out.append({
                "report_id": rec.report_id,
                "data_riferimento": rec.data_riferimento,
                "tavola": "1.1",
                "titolo_tabella": rec.titoli.get("1.1", ""),
                "dimensione": "regione",
                "etichetta": r["regione"],
                "variabile": var,
                "percorso": None,
                "unita_misura": "percentuale" if var == "incidenza_pc"
                                 else "valore_assoluto",
                "valore": r.get(var),
            })
    return out


PERCORSI_LABEL = {
    "1": "1_reinserimento_lavorativo",
    "2": "2_aggiornamento_upskilling",
    "3": "3_riqualificazione_reskilling",
    "4": "4_lavoro_inclusione",
    "5": "5_ricollocazione_collettiva",
}


def to_long_1_2(rec: Estrazione) -> List[dict]:
    out: List[dict] = []
    for r in rec.tab_1_2:
        for k, v in r.items():
            if k == "regione":
                continue
            m = re.match(r"perc(\d)_(ass|pc)", k)
            if not m:
                continue
            n_perc, tipo = m.group(1), m.group(2)
            percorso = PERCORSI_LABEL[n_perc]
            unita = "valore_assoluto" if tipo == "ass" else "percentuale_riga"
            out.append({
                "report_id": rec.report_id,
                "data_riferimento": rec.data_riferimento,
                "tavola": "1.2",
                "titolo_tabella": rec.titoli.get("1.2", ""),
                "dimensione": "regione",
                "etichetta": r["regione"],
                "variabile": f"{percorso}_{tipo}",
                "percorso": percorso,
                "unita_misura": unita,
                "valore": v,
            })
    return out


def to_long_2_1(rec: Estrazione) -> List[dict]:
    out: List[dict] = []
    for r in rec.tab_2_1:
        for k, v in r.items():
            if k == "regione":
                continue
            unita = "percentuale" if k.endswith("_pc") else "valore_assoluto"
            out.append({
                "report_id": rec.report_id,
                "data_riferimento": rec.data_riferimento,
                "tavola": "2.1",
                "titolo_tabella": rec.titoli.get("2.1", ""),
                "dimensione": "regione",
                "etichetta": r["regione"],
                "variabile": k,
                "percorso": None,
                "unita_misura": unita,
                "valore": v,
            })
    return out


def to_long_2_2(rec: Estrazione) -> List[dict]:
    out: List[dict] = []
    for r in rec.tab_2_2:
        for k, v in r.items():
            if k in ("dimensione", "etichetta", "percorso"):
                continue
            unita = ("percentuale"
                     if k.endswith("_pc") or k == "quota_nuovi_su_occ"
                     else "valore_assoluto")
            out.append({
                "report_id": rec.report_id,
                "data_riferimento": rec.data_riferimento,
                "tavola": "2.2",
                "titolo_tabella": rec.titoli.get("2.2", ""),
                "dimensione": r["dimensione"],
                "etichetta": r["etichetta"],
                "variabile": k,
                "percorso": r["percorso"],
                "unita_misura": unita,
                "valore": v,
            })
    return out


# ---- 8. Scrittura CSV -------------------------------------------------------

def scrivi_csv(path: Path, righe: List[dict]) -> None:
    if not righe:
        path.write_text("")
        return
    # unione di tutte le chiavi in ordine di prima apparizione
    ordine: List[str] = []
    for r in righe:
        for k in r.keys():
            if k not in ordine:
                ordine.append(k)
    with path.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=ordine)
        w.writeheader()
        for r in righe:
            row = {}
            for k in ordine:
                v = r.get(k)
                if isinstance(v, date):
                    row[k] = v.isoformat()
                elif v is None:
                    row[k] = ""
                else:
                    row[k] = v
            w.writerow(row)


_WIDE_ATTR_TO_TAVOLA = {
    "tab_1_1": "1.1",
    "tab_1_2": "1.2",
    "tab_2_1": "2.1",
    "tab_2_2": "2.2",
}


def appiana_wide(records: List[Estrazione], attr: str) -> List[dict]:
    tavola = _WIDE_ATTR_TO_TAVOLA[attr]
    out: List[dict] = []
    for rec in records:
        titolo = rec.titoli.get(tavola, "")
        for r in getattr(rec, attr):
            d = {"report_id": rec.report_id,
                 "data_riferimento": rec.data_riferimento,
                 "titolo_tabella": titolo,
                 **r}
            out.append(d)
    return out


# ---- 9. Main ---------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Estrae le tavole regionali dai report INAPP Focus GOL.",
    )
    ap.add_argument("--input-dir", required=True, type=Path,
                    help="Cartella contenente i PDF di Inapp Focus GOL.")
    ap.add_argument("--output-dir", required=True, type=Path,
                    help="Cartella di destinazione dei CSV.")
    ap.add_argument("--pattern", default=r".*\.pdf$",
                    help="Regex sul nome file (default: tutti i .pdf).")
    args = ap.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    rx_file = re.compile(args.pattern, re.IGNORECASE)
    files = sorted(p for p in args.input_dir.iterdir()
                   if p.is_file() and rx_file.search(p.name))
    if not files:
        print(f"Nessun PDF trovato in {args.input_dir}", file=sys.stderr)
        return 1

    estrazioni = [processa_pdf(f) for f in files]

    long_records = []
    for e in estrazioni:
        long_records.extend(to_long_1_1(e))
        long_records.extend(to_long_1_2(e))
        long_records.extend(to_long_2_1(e))
        long_records.extend(to_long_2_2(e))

    # ordinamento
    long_records.sort(
        key=lambda r: (
            r["data_riferimento"] or date(1900, 1, 1),
            r["tavola"], r["dimensione"], r["etichetta"], r["variabile"]
        )
    )

    out = args.output_dir
    scrivi_csv(out / "tab_1_1_long.csv",
               [r for r in long_records if r["tavola"] == "1.1"])
    scrivi_csv(out / "tab_1_2_long.csv",
               [r for r in long_records if r["tavola"] == "1.2"])
    scrivi_csv(out / "tab_2_1_long.csv",
               [r for r in long_records if r["tavola"] == "2.1"])
    scrivi_csv(out / "tab_2_2_long.csv",
               [r for r in long_records if r["tavola"] == "2.2"])
    scrivi_csv(out / "tab_long_completo.csv", long_records)

    scrivi_csv(out / "tab_1_1_wide.csv", appiana_wide(estrazioni, "tab_1_1"))
    scrivi_csv(out / "tab_1_2_wide.csv", appiana_wide(estrazioni, "tab_1_2"))
    scrivi_csv(out / "tab_2_1_wide.csv", appiana_wide(estrazioni, "tab_2_1"))
    scrivi_csv(out / "tab_2_2_wide.csv", appiana_wide(estrazioni, "tab_2_2"))

    # diagnostica
    diag = []
    for e in estrazioni:
        for tav, dati in (("1.1", e.tab_1_1), ("1.2", e.tab_1_2),
                           ("2.1", e.tab_2_1), ("2.2", e.tab_2_2)):
            diag.append({
                "report_id": e.report_id,
                "data_riferimento": e.data_riferimento,
                "tavola": tav,
                "n_righe": len(dati),
            })
    scrivi_csv(out / "diagnostica.csv", diag)

    # report a video
    print()
    print("=== Riepilogo estrazione ===")
    print(f"File processati:       {len(files)}")
    for e in estrazioni:
        print(f"\n{e.report_id} — {e.data_riferimento}"
              f"  anni 1.1: {','.join(e.anni_tab_1_1) or '-'}")
        print(f"  Tavola 1.1: {len(e.tab_1_1):3d} righe")
        print(f"  Tavola 1.2: {len(e.tab_1_2):3d} righe")
        print(f"  Tavola 2.1: {len(e.tab_2_1):3d} righe")
        print(f"  Tavola 2.2: {len(e.tab_2_2):3d} righe")
    print(f"\nOutput in: {out.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

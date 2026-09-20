from datetime import datetime
from pathlib import Path
import re

import pandas as pd
from sqlalchemy import text

from app.data_access.database import get_databases, get_engine


EXPORT_DIR = Path(__file__).parent.parent / "exports"
PERIOD_PATTERN = re.compile(r"^\d{4}(0[1-9]|1[0-2])$")

DETAIL_SHEETS_BY_DATABASE = {
    "MMTMS": ("MMFR", "MMBE"),
    "MMTMSACT": ("ACTE",),
    "MMTMSITP": ("ITPL",),
    "MMTMSIRF": ("RAIL",),
}

SYNTHESE_QUERY = text("""
    SELECT societe,
           :periode AS periode,
           section,
           SUM(ventes) AS ventes_fae
    FROM bi.finance_details_fae(:periode)
    GROUP BY societe, section
    ORDER BY societe, section
""")

DETAIL_QUERY = text("""
    SELECT *
    FROM bi.finance_details_fae(:periode)
    WHERE societe = :societe
""")


def _normaliser_base(database: str) -> str:
    return database.strip().upper()


def saisir_periode() -> str:
    """Demande une période comptable au format AAAAMM."""
    while True:
        periode = input("Période (AAAAMM, par exemple 202608) : ").strip()
        if PERIOD_PATTERN.fullmatch(periode):
            return periode
        print("Période invalide. Saisissez une période au format AAAAMM.")


def get_ventes_fae(database: str, periode: str) -> tuple[pd.DataFrame, dict[str, pd.DataFrame]]:
    """Retourne la synthèse et les détails des sociétés de la base indiquée."""
    database_key = _normaliser_base(database)
    societes = DETAIL_SHEETS_BY_DATABASE.get(database_key)
    if societes is None:
        raise ValueError(f"Base PostgreSQL non prise en charge : '{database}'.")

    engine = get_engine(database)
    try:
        synthese = pd.read_sql(SYNTHESE_QUERY, engine, params={"periode": periode})
        details = {
            societe: pd.read_sql(
                DETAIL_QUERY,
                engine,
                params={"periode": periode, "societe": societe},
            )
            for societe in societes
        }
    finally:
        engine.dispose()

    return synthese, details


def collecter_ventes_fae(periode: str) -> tuple[pd.DataFrame, dict[str, pd.DataFrame]]:
    """Collecte la synthèse des quatre bases et les détails par société."""
    syntheses = []
    details_par_societe = {}

    for database in get_databases():
        synthese, details = get_ventes_fae(database, periode)
        if not synthese.empty:
            syntheses.append(synthese)
        details_par_societe.update(details)

    synthese_complete = (
        pd.concat(syntheses, ignore_index=True)
        if syntheses
        else pd.DataFrame(columns=["societe", "periode", "section", "ventes_fae"])
    )
    return synthese_complete, details_par_societe


def export_excel(periode: str, synthese: pd.DataFrame, details: dict[str, pd.DataFrame]) -> Path:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    filename = EXPORT_DIR / f"{datetime.now():%Y%m%d_%H%M%S}_details_ventes_fae_{periode}.xlsx"

    with pd.ExcelWriter(filename, engine="openpyxl") as writer:
        synthese.to_excel(writer, index=False, sheet_name="SYNTHESE")
        for sheet_name in ("MMFR", "MMBE", "ACTE", "ITPL", "RAIL"):
            details.get(sheet_name, pd.DataFrame()).to_excel(
                writer,
                index=False,
                sheet_name=sheet_name,
            )

    return filename


def main() -> None:
    try:
        periode = saisir_periode()
        synthese, details = collecter_ventes_fae(periode)
        filename = export_excel(periode, synthese, details)
        print(f"{len(synthese)} ligne(s) dans l'onglet SYNTHESE")
        print(f"Export : {filename}")
    except Exception as error:
        print(f"ERREUR : {error}")


if __name__ == "__main__":
    main()

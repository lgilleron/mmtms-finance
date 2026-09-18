from datetime import datetime
from pathlib import Path

import pandas as pd

from app.data_access.database import get_ms_databases
from app.data_access.sql_runner import execute_ms_sql_file
from app.ventes_section_mmtms import control_ventes_section as get_ventes_mmtms


BASE_DIR = Path(__file__).parent.parent
CEGID_SQL_FILE = BASE_DIR / "sql" / "ventes_section_cegid.sql"
EXPORT_DIR = BASE_DIR / "exports"

# Les codes société ne sont pas retournés par la requête Cegid : ils sont
# déterminés par la base SQL Server qui a fourni les données.
SOCIETE_PAR_BASE_CEGID = {
    "MMFRANCE": "MMFR",
    "ACTE_TEMP": "ACTE",
    "ITP": "ITPL",
    "IRF": "RAIL",
}

COLONNES_CLES = ["societe", "section", "periodecpt"]
COLONNES_VENTES = ["ventes"]
TOLERANCE_ECART = 0.01


def _normaliser_base(database: str) -> str:
    return database.strip().upper()


def _verifier_colonnes(df: pd.DataFrame, colonnes: list[str], source: str) -> None:
    manquantes = set(colonnes).difference(df.columns)
    if manquantes:
        raise ValueError(
            f"Colonnes manquantes dans les données {source} : {', '.join(sorted(manquantes))}"
        )


def get_ventes_cegid() -> pd.DataFrame:
    """Extrait les ventes Cegid en ajoutant la société déduite de la base."""
    resultats = []
    for database in get_ms_databases():
        societe = SOCIETE_PAR_BASE_CEGID.get(_normaliser_base(database))
        if societe is None:
            raise ValueError(
                f"Aucune société configurée pour la base Cegid '{database}'. "
                f"Complétez SOCIETE_PAR_BASE_CEGID."
            )

        df = execute_ms_sql_file(CEGID_SQL_FILE, database)
        if not df.empty:
            _verifier_colonnes(df, ["section", "periodecpt", *COLONNES_VENTES], "Cegid")
            df = df.copy()
            df["societe"] = societe
            resultats.append(df[[*COLONNES_CLES, *COLONNES_VENTES]])

    return pd.concat(resultats, ignore_index=True) if resultats else pd.DataFrame(columns=[*COLONNES_CLES, *COLONNES_VENTES])


def _aggreger(df: pd.DataFrame, source: str) -> pd.DataFrame:
    _verifier_colonnes(df, [*COLONNES_CLES, *COLONNES_VENTES], source)
    resultat = df[[*COLONNES_CLES, *COLONNES_VENTES]].copy()
    resultat["societe"] = resultat["societe"].astype(str).str.strip().str.upper()
    resultat["section"] = resultat["section"].astype(str).str.strip().str.upper()
    resultat["periodecpt"] = resultat["periodecpt"].astype(str).str.strip()
    resultat["ventes"] = pd.to_numeric(resultat["ventes"], errors="raise")
    return resultat.groupby(COLONNES_CLES, as_index=False, dropna=False)["ventes"].sum()


def rapprocher_ventes(mmtms: pd.DataFrame, cegid: pd.DataFrame) -> pd.DataFrame:
    """Retourne un rapprochement complet, y compris les lignes absentes d'une source."""
    mmtms_agrege = _aggreger(mmtms, "MMTMS").rename(columns={"ventes": "ventes_mmtms"})
    cegid_agrege = _aggreger(cegid, "Cegid").rename(columns={"ventes": "ventes_cegid"})

    rapprochement = mmtms_agrege.merge(
        cegid_agrege,
        on=COLONNES_CLES,
        how="outer",
        indicator=True,
    )
    rapprochement["ecart"] = (
        rapprochement["ventes_mmtms"].fillna(0) - rapprochement["ventes_cegid"].fillna(0)
    ).round(2)
    rapprochement["statut"] = "Conforme"
    rapprochement.loc[rapprochement["_merge"] == "left_only", "statut"] = "Absente de Cegid"
    rapprochement.loc[rapprochement["_merge"] == "right_only", "statut"] = "Absente de MMTMS"
    rapprochement.loc[
        (rapprochement["_merge"] == "both")
        & (rapprochement["ecart"].abs() > TOLERANCE_ECART),
        "statut",
    ] = "Ecart"

    return (
        rapprochement.drop(columns="_merge")
        .sort_values(COLONNES_CLES)
        .reset_index(drop=True)
    )


def export_excel(rapprochement: pd.DataFrame) -> Path:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    filename = EXPORT_DIR / f"{datetime.now():%Y%m%d_%H%M%S}_ventes_section_rapprochement.xlsx"
    ecarts = rapprochement[rapprochement["statut"] != "Conforme"]
    with pd.ExcelWriter(filename, engine="openpyxl") as writer:
        rapprochement.to_excel(writer, index=False, sheet_name="Rapprochement")
        ecarts.to_excel(writer, index=False, sheet_name="Ecarts")
    return filename


def main() -> None:
    try:
        rapprochement = rapprocher_ventes(get_ventes_mmtms(), get_ventes_cegid())
        fichier = export_excel(rapprochement)
        nombre_ecarts = (rapprochement["statut"] != "Conforme").sum()
        print(f"{len(rapprochement)} lignes rapprochées, {nombre_ecarts} écart(s)")
        print(f"Export : {fichier}")
    except Exception as error:
        print(f"ERREUR : {error}")


if __name__ == "__main__":
    main()

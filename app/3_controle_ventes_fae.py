from datetime import datetime
from pathlib import Path

import pandas as pd

from app.data_access.database import get_databases, get_engine


EXPORT_DIR = Path(__file__).parent.parent / "exports"
DIFFERENCE_COLUMN = "difference"
CONTROLE_VIEW = "bi.finance_controle_ventes_fae"


def get_ventes_fae_from_view(database: str) -> pd.DataFrame:
    """Lit la vue de contrôle FAE dans une base PostgreSQL."""
    engine = get_engine(database)
    try:
        return pd.read_sql(f"SELECT * FROM {CONTROLE_VIEW}", engine)
    finally:
        engine.dispose()


def control_ventes_fae() -> pd.DataFrame:
    """Lit le contrôle FAE sur chaque base PostgreSQL configurée."""
    results = []
    for database in get_databases():
        df = get_ventes_fae_from_view(database)
        if not df.empty:
            results.append(df)

    return pd.concat(results, ignore_index=True) if results else pd.DataFrame()


def export_excel(df: pd.DataFrame) -> Path:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    filename = EXPORT_DIR / f"{datetime.now():%Y%m%d_%H%M%S}_controle_ventes_fae.xlsx"
    df.to_excel(filename, index=False, sheet_name="Controle FAE")
    return filename


def count_non_zero_differences(df: pd.DataFrame) -> int:
    if DIFFERENCE_COLUMN not in df.columns:
        raise ValueError(f"Colonne '{DIFFERENCE_COLUMN}' absente du résultat de la vue.")

    differences = pd.to_numeric(df[DIFFERENCE_COLUMN], errors="raise")
    return int(differences.ne(0).sum())


def main() -> None:
    try:
        df = control_ventes_fae()
        filename = export_excel(df)
        non_zero_differences = count_non_zero_differences(df) if not df.empty else 0

        print(f"{len(df)} ligne(s) trouvée(s)")
        print(f"{non_zero_differences} ligne(s) avec une différence non nulle")
        print(f"Export : {filename}")
    except Exception as error:
        print(f"ERREUR : {error}")


if __name__ == "__main__":
    main()

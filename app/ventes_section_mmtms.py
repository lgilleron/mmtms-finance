from pathlib import Path
from datetime import datetime
import pandas as pd
from app.data_access.database import get_databases
from app.data_access.sql_runner import execute_sql_file

BASE_DIR = Path(__file__).parent.parent
SQL_FILE = BASE_DIR / "sql" / "ventes_section_mmtms.sql"
EXPORT_DIR = BASE_DIR / "exports"


def control_ventes_section():
    results = []
    for database in get_databases():
        df = execute_sql_file(SQL_FILE, database)
        if not df.empty:
            results.append(df)
    return pd.concat(results, ignore_index=True) if results else pd.DataFrame()


def export_excel(df):
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = EXPORT_DIR / f"{timestamp}_ventes_section_mmtms.xlsx"
    df.to_excel(filename, index=False, sheet_name="Ventes")
    return filename


def main():
    try:
        df = control_ventes_section()
        count = len(df)
        print(f"{count} lignes ventes")
        export_excel(df)
    except Exception as error:
        print(f"ERREUR : {error}")


if __name__ == "__main__":
    main()

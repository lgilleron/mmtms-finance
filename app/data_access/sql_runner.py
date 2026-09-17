from pathlib import Path
import pandas as pd
from app.data_access.database import get_engine

def execute_sql_file(sql_file, database):
    sql_path = Path(sql_file)
    if not sql_path.exists():
        raise FileNotFoundError(f"Fichier SQL introuvable : {sql_path}")
    sql = sql_path.read_text(encoding="utf-8")
    engine = get_engine(database)
    try:
        return pd.read_sql(sql, engine)
    finally:
        engine.dispose()

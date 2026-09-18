from pathlib import Path
import pandas as pd
from app.data_access.database import get_engine, get_ms_engine

def execute_sql_file(sql_file, database):
    return _execute_sql_file(sql_file, get_engine(database))


def execute_ms_sql_file(sql_file, database):
    return _execute_sql_file(sql_file, get_ms_engine(database))


def _execute_sql_file(sql_file, engine):
    sql_path = Path(sql_file)
    if not sql_path.exists():
        raise FileNotFoundError(f"Fichier SQL introuvable : {sql_path}")
    sql = sql_path.read_text(encoding="utf-8")
    try:
        return pd.read_sql(sql, engine)
    finally:
        engine.dispose()

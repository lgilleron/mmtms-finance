import os
from urllib.parse import quote_plus

import pyodbc
import psycopg
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()


def get_databases():
    return [db.strip() for db in os.getenv("PGDATABASES", "").split(",") if db.strip()]


def get_connection(database):
    return psycopg.connect(
        host=os.getenv("PGHOST"),
        port=os.getenv("PGPORT", "5432"),
        dbname=database,
        user=os.getenv("PGUSER"),
        password=os.getenv("PGPASSWORD")
    )


def get_engine(database):
    return create_engine(
        f"postgresql+psycopg://{os.getenv('PGUSER')}:{os.getenv('PGPASSWORD')}@{os.getenv('PGHOST')}:{os.getenv('PGPORT', '5432')}/{database}"
    )


def get_ms_databases():
    return [db.strip() for db in os.getenv("MSDATABASES", "").split(",") if db.strip()]


def get_ms_odbc_driver():
    configured_driver = os.getenv("MSODBCDRIVER")
    if configured_driver:
        return configured_driver

    installed_drivers = pyodbc.drivers()
    for driver in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server"):
        if driver in installed_drivers:
            return driver

    raise RuntimeError(
        "Aucun pilote ODBC SQL Server n'est installé. "
        "Installez-en un ou définissez MSODBCDRIVER dans le fichier .env."
    )


def get_ms_engine(database):
    instance = os.getenv("MSINSTANCE")
    port = os.getenv("MSPORT", "1433")
    if instance:
        server = f"{os.getenv('MSHOST')}\\{instance},{port}"
    else:
        server = f"{os.getenv('MSHOST')},{port}"

    driver = get_ms_odbc_driver()
    connection_parts = [
        f"DRIVER={{{driver}}}",
        f"SERVER={server}",
        f"DATABASE={database}",
        f"UID={os.getenv('MSUSER')}",
        f"PWD={os.getenv('MSPASSWORD')}",
    ]
    if driver != "SQL Server":
        connection_parts.append("TrustServerCertificate=yes")

    connection_string = quote_plus(";".join(connection_parts) + ";")
    return create_engine(f"mssql+pyodbc:///?odbc_connect={connection_string}")

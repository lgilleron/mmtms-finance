import os
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
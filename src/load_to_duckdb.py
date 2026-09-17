import duckdb
from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data" / "raw"
DATABASE_DIR = PROJECT_ROOT / "database"

# Create database folder if it doesn't exist
DATABASE_DIR.mkdir(exist_ok=True)

# DuckDB database
DB_PATH = DATABASE_DIR / "olist.duckdb"

# Connect to DuckDB
con = duckdb.connect(str(DB_PATH))

print("Connected to DuckDB")
print(f"Database: {DB_PATH}")

# CSV files
tables = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

# Load each CSV into a DuckDB table
for table_name, file_name in tables.items():

    file_path = DATA_DIR / file_name

    print(f"Loading {file_name}...")

    con.execute(f"""
        CREATE OR REPLACE TABLE {table_name} AS
        SELECT *
        FROM read_csv_auto('{file_path.as_posix()}')
    """)

    count = con.execute(
        f"SELECT COUNT(*) FROM {table_name}"
    ).fetchone()[0]

    print(f"  ✓ {table_name}: {count:,} rows")

print("\nAll tables loaded successfully.")

print("\nTables in database:")
print(con.execute("SHOW TABLES").fetchdf())

con.close()

print("\nDatabase connection closed.")
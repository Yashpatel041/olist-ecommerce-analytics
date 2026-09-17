import duckdb
from pathlib import Path
import sys

# Project paths
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "database" / "olist.duckdb"
SQL_DIR = PROJECT_ROOT / "sql"

# Check if SQL filename was provided
if len(sys.argv) < 2:
    print("Usage: python run_sql.py <sql_file>")
    sys.exit(1)

# SQL file provided by user
sql_file = SQL_DIR / sys.argv[1]

# Check if file exists
if not sql_file.exists():
    print(f"SQL file not found: {sql_file}")
    sys.exit(1)

# Connect to DuckDB
con = duckdb.connect(str(DB_PATH))

print(f"Connected to: {DB_PATH}")
print(f"Running: {sql_file}\n")

# Read SQL file
sql = sql_file.read_text(encoding="utf-8")

# Split SQL statements
statements = [
    statement.strip()
    for statement in sql.split(";")
    if statement.strip()
]

# Execute statements
for i, statement in enumerate(statements, start=1):

    print("=" * 70)
    print(f"QUERY {i}")
    print("=" * 70)
    print(statement)

    try:
        result = con.execute(statement)

        try:
            print("\nRESULT:")
            print(result.fetchdf())
        except Exception:
            pass

    except Exception as e:
        print(f"\nERROR: {e}")

    print()

con.close()

print("SQL execution completed.")
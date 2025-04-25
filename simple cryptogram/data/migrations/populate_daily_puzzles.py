import sqlite3
from datetime import datetime, timedelta

# Path to your quotes.db
DB_PATH = "quotes.db"
START_DATE = datetime(2025, 4, 23)
NUM_DAYS = 365

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()

# Get up to 365 medium difficulty quote IDs
c.execute("SELECT id FROM quotes WHERE difficulty = 'medium' LIMIT ?;", (NUM_DAYS,))
quote_ids = [row[0] for row in c.fetchall()]

for i, quote_id in enumerate(quote_ids):
    puzzle_date = (START_DATE + timedelta(days=i)).strftime('%Y-%m-%d')
    c.execute("INSERT OR IGNORE INTO daily_puzzles (quote_id, puzzle_date) VALUES (?, ?);", (quote_id, puzzle_date))

conn.commit()
conn.close()
print(f"Populated {len(quote_ids)} daily puzzles starting from {START_DATE.strftime('%Y-%m-%d')}")

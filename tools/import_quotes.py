#!/usr/bin/env python3
"""
Quote Import Pipeline for Simple Cryptogram
=============================================
Imports quotes from a JSON file or the Zen Quotes API, deduplicates, encodes, and inserts
into the database. New authors are inserted with empty biographical data — use
enrich_authors.py to fill those in.

Usage:
  # Import from JSON file (preview)
  python3 import_quotes.py --source quotes.json --preview

  # Import from JSON file
  python3 import_quotes.py --source quotes.json --import

  # Import from Zen Quotes API (preview)
  python3 import_quotes.py --source zenquotes --preview

  # Import from Zen Quotes API
  python3 import_quotes.py --source zenquotes --import --batches 10

Requirements:
  pip install requests  (only needed for zenquotes source)
"""

import argparse
import json
import os
import random
import sqlite3
import string
import sys
import time

# --- Config ---
DB_PATH = os.path.join(os.path.dirname(__file__),
                       "..", "simple cryptogram", "data", "quotes.db")
ZEN_QUOTES_URL = "https://zenquotes.io/api/quotes"
RATE_LIMIT_DELAY = 10  # seconds between API calls (5 req / 30s limit)


# --- Fetch: JSON file ---

def fetch_from_json(file_path):
    """Load quotes from a JSON file. Expects [{"author": "...", "text": "..."}, ...]"""
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    quotes = []
    seen = set()
    for item in data:
        quote_text = item.get("text", "").strip()
        author = item.get("author", "").strip()
        if not quote_text or not author:
            continue
        key = (quote_text.lower(), author.lower())
        if key not in seen:
            seen.add(key)
            quotes.append({"quote_text": quote_text, "author": author})

    print(f"  Loaded {len(quotes)} unique quotes from {os.path.basename(file_path)}")
    return quotes


# --- Fetch: Zen Quotes API ---

def fetch_from_zenquotes(num_batches=10):
    """Fetch quotes from Zen Quotes API in batches.
    Each batch returns ~50 quotes. Rate limited to 5 req/30s."""
    try:
        import requests
    except ImportError:
        print("Error: 'requests' package required. Run: pip install requests")
        sys.exit(1)

    all_quotes = []
    seen = set()

    for i in range(num_batches):
        print(f"  Fetching batch {i+1}/{num_batches}...", end=" ", flush=True)
        try:
            resp = requests.get(ZEN_QUOTES_URL, timeout=15)
            resp.raise_for_status()
            data = resp.json()
        except Exception as e:
            print(f"Error: {e}")
            if i > 0:
                print(f"  Continuing with {len(all_quotes)} quotes fetched so far.")
                break
            raise

        batch_new = 0
        for item in data:
            quote_text = item.get("q", "").strip()
            author = item.get("a", "").strip()
            if not quote_text or not author or author == "zenquotes.io":
                continue
            key = (quote_text.lower(), author.lower())
            if key not in seen:
                seen.add(key)
                all_quotes.append({"quote_text": quote_text, "author": author})
                batch_new += 1
        print(f"{batch_new} new quotes")

        if i < num_batches - 1:
            time.sleep(RATE_LIMIT_DELAY)

    print(f"  Total fetched: {len(all_quotes)} unique quotes")
    return all_quotes


# --- Deduplicate against existing database ---

def deduplicate(quotes, db_path):
    """Remove quotes that already exist in the database."""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT LOWER(quote_text) FROM quotes")
    existing = {row[0] for row in c.fetchall()}
    conn.close()

    new_quotes = [q for q in quotes if q["quote_text"].lower() not in existing]
    dupes = len(quotes) - len(new_quotes)
    print(f"  Deduplicated: {dupes} duplicates removed, {len(new_quotes)} new quotes")
    return new_quotes


# --- Encode quotes ---

def generate_letter_encoding(quote_text):
    """Generate a random letter substitution cipher."""
    letters = list(string.ascii_uppercase)
    shuffled = list(string.ascii_uppercase)

    # Shuffle until no letter maps to itself
    while True:
        random.shuffle(shuffled)
        if all(a != b for a, b in zip(letters, shuffled)):
            break

    mapping = dict(zip(letters, shuffled))
    key = "".join(shuffled)  # 26-char key string

    encoded = []
    for ch in quote_text.upper():
        if ch in mapping:
            encoded.append(mapping[ch])
        else:
            encoded.append(ch)

    return "".join(encoded), key


def generate_number_encoding(quote_text):
    """Generate a random number substitution cipher."""
    letters = list(string.ascii_uppercase)
    numbers = list(range(1, 27))
    random.shuffle(numbers)

    mapping = dict(zip(letters, numbers))
    key = ",".join(str(n) for n in numbers)  # comma-separated key

    encoded_parts = []
    for ch in quote_text.upper():
        if ch in mapping:
            encoded_parts.append(str(mapping[ch]))
        elif ch == " ":
            encoded_parts.append(" ")
        else:
            encoded_parts.append(ch)

    return " ".join(encoded_parts), key


def classify_difficulty(quote_text):
    """Classify quote difficulty by character length."""
    length = len(quote_text)
    if length < 50:
        return "easy"
    elif length < 100:
        return "medium"
    else:
        return "hard"


def encode_quotes(quotes):
    """Add encoding data and difficulty to each quote."""
    for q in quotes:
        text = q["quote_text"]
        q["length"] = len(text)
        q["difficulty"] = classify_difficulty(text)
        q["letter_encoded"], q["letter_key"] = generate_letter_encoding(text)
        q["number_encoded"], q["number_key"] = generate_number_encoding(text)
    print(f"  Encoded {len(quotes)} quotes")
    easy = sum(1 for q in quotes if q["difficulty"] == "easy")
    med = sum(1 for q in quotes if q["difficulty"] == "medium")
    hard = sum(1 for q in quotes if q["difficulty"] == "hard")
    print(f"  Difficulty breakdown: {easy} easy, {med} medium, {hard} hard")
    return quotes


# --- Insert into database ---

def get_new_authors(quotes, db_path):
    """Find authors in the new quotes that don't exist in the database."""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT LOWER(name) FROM authors")
    existing = {row[0] for row in c.fetchall()}
    conn.close()

    new_authors = set()
    for q in quotes:
        if q["author"].lower() not in existing:
            new_authors.add(q["author"])

    return sorted(new_authors)


def insert_into_db(quotes, new_authors, db_path):
    """Insert new quotes, encodings, and placeholder authors into the database."""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    # Insert new authors with empty biographical data
    authors_inserted = 0
    for name in new_authors:
        try:
            c.execute("""
                INSERT OR IGNORE INTO authors (name, full_name)
                VALUES (?, ?)
            """, (name, name))
            if c.rowcount > 0:
                authors_inserted += 1
        except Exception as e:
            print(f"    Warning: Failed to insert author '{name}': {e}")

    # Insert quotes and encodings
    quotes_inserted = 0
    for q in quotes:
        try:
            c.execute("""
                INSERT INTO quotes (quote_text, author, length, difficulty)
                VALUES (?, ?, ?, ?)
            """, (q["quote_text"], q["author"], q["length"], q["difficulty"]))
            quote_id = c.lastrowid

            c.execute("""
                INSERT INTO encoded_quotes (quote_id, letter_encoded, letter_key,
                    number_encoded, number_key)
                VALUES (?, ?, ?, ?, ?)
            """, (quote_id, q["letter_encoded"], q["letter_key"],
                  q["number_encoded"], q["number_key"]))
            quotes_inserted += 1
        except Exception as e:
            print(f"    Warning: Failed to insert quote: {e}")

    conn.commit()
    conn.close()
    print(f"  Inserted: {quotes_inserted} quotes, {authors_inserted} new authors")
    if authors_inserted > 0:
        print(f"  Run enrich_authors.py to fill in biographical data for new authors")


# --- Main ---

def main():
    parser = argparse.ArgumentParser(description="Import quotes into Simple Cryptogram")
    parser.add_argument("--source", required=True,
                        help="Quote source: path to a JSON file, or 'zenquotes' for API")
    parser.add_argument("--preview", action="store_true",
                        help="Preview without importing")
    parser.add_argument("--import", dest="do_import", action="store_true",
                        help="Import into database")
    parser.add_argument("--batches", type=int, default=10,
                        help="Number of API batches for zenquotes source (default: 10)")
    args = parser.parse_args()

    if not args.preview and not args.do_import:
        parser.print_help()
        sys.exit(1)

    db_path = os.path.abspath(DB_PATH)
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}")
        sys.exit(1)

    print(f"Database: {db_path}")
    print()

    # Step 1: Fetch
    if args.source.lower() == "zenquotes":
        print("Step 1: Fetching quotes from Zen Quotes API...")
        quotes = fetch_from_zenquotes(num_batches=args.batches)
    else:
        source_path = os.path.abspath(args.source)
        if not os.path.exists(source_path):
            print(f"Error: Source file not found at {source_path}")
            sys.exit(1)
        print(f"Step 1: Loading quotes from {os.path.basename(source_path)}...")
        quotes = fetch_from_json(source_path)
    print()

    # Step 2: Deduplicate
    print("Step 2: Deduplicating against database...")
    quotes = deduplicate(quotes, db_path)
    if not quotes:
        print("  No new quotes to import. Done.")
        return
    print()

    # Step 3: Encode
    print("Step 3: Encoding quotes...")
    quotes = encode_quotes(quotes)
    print()

    # Find new authors
    new_authors = get_new_authors(quotes, db_path)

    if args.preview:
        print("=== PREVIEW (no changes made) ===")
        print(f"  New quotes: {len(quotes)}")
        print(f"  New authors: {len(new_authors)}")
        if new_authors:
            print(f"  Authors: {', '.join(new_authors[:20])}")
            if len(new_authors) > 20:
                print(f"  ... and {len(new_authors) - 20} more")
        print()
        print("Sample quotes:")
        for q in quotes[:5]:
            print(f'  [{q["difficulty"]}] "{q["quote_text"][:80]}..." — {q["author"]}')
        return

    # Step 4: Insert
    print("Step 4: Inserting into database...")
    insert_into_db(quotes, new_authors, db_path)
    print()
    print("Done!")


if __name__ == "__main__":
    main()

# Database Schema for quotes.db

```
CREATE TABLE quotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quote_text TEXT NOT NULL,
    author TEXT NOT NULL,
    length INTEGER NOT NULL,
    difficulty TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sqlite_sequence(name,seq);

CREATE TABLE encoded_quotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quote_id INTEGER NOT NULL,
    letter_encoded TEXT NOT NULL,
    letter_key TEXT NOT NULL,
    number_encoded TEXT NOT NULL,
    number_key TEXT NOT NULL,
    FOREIGN KEY (quote_id) REFERENCES quotes (id)
);

CREATE TABLE authors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    full_name TEXT,
    birth_date TEXT,
    death_date TEXT,
    place_of_birth TEXT,
    place_of_death TEXT,
    summary TEXT
);

CREATE TABLE daily_puzzles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quote_id INTEGER NOT NULL,
    puzzle_date DATE NOT NULL UNIQUE,
    FOREIGN KEY (quote_id) REFERENCES quotes(id)
);

```

Note: The table `sqlite_sequence` is an internal SQLite table for AUTOINCREMENT values and is not part of the user-defined schema.

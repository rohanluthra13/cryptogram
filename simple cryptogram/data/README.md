# Database

SQLite database (`quotes.db`) containing all puzzle content.

## Schema

### quotes
| Column | Type | Description |
|---|---|---|
| id | INTEGER PK | Auto-increment |
| quote_text | TEXT | Original quote |
| author | TEXT | Author name (matches `authors.name`) |
| length | INTEGER | Character count |
| difficulty | TEXT | easy (<50 chars), medium (50-99), hard (100+) |

### encoded_quotes
| Column | Type | Description |
|---|---|---|
| quote_id | INTEGER FK | References `quotes.id` |
| letter_encoded | TEXT | Letter substitution cipher text |
| letter_key | TEXT | 26-char key (e.g., "ELJGACIXMODFRSUTBKVHZPWYNQ") |
| number_encoded | TEXT | Number substitution cipher text |
| number_key | TEXT | Comma-separated mapping (e.g., "10,11,5,2,...") |

### authors
| Column | Type | Description |
|---|---|---|
| name | TEXT UNIQUE | Display name (matches `quotes.author`) |
| full_name | TEXT | Full legal/birth name |
| birth_date | TEXT | YYYY-MM-DD, YYYY, or NULL |
| death_date | TEXT | YYYY-MM-DD, or NULL if alive |
| place_of_birth | TEXT | City, Region, Country or NULL |
| place_of_death | TEXT | City, Region, Country or NULL |
| summary | TEXT | 2-3 sentence biography |

### daily_puzzles
| Column | Type | Description |
|---|---|---|
| quote_id | INTEGER FK | References `quotes.id` |
| puzzle_date | DATE UNIQUE | One puzzle per day |

## Data Sources

- **Zen Quotes API** (zenquotes.io) — original ~2,900 quotes
- **dwyl/quotes** (github.com/dwyl/quotes) — ~1,500 additional quotes
- **Author bios** — generated via Claude API / Claude Code subagents

## Current Stats (March 2026)

- 4,325 quotes (904 easy, 2,521 medium, 900 hard)
- 811 authors, all with biographical data
- 1,095 daily puzzles scheduled (2025-04-23 through 2028-04-21)
- 3,232 quotes available for regular play (not used in daily puzzles)

## Files

- `quotes.db` — SQLite database (bundled in app)
- `quotes.json` — dwyl/quotes source data
- `migrations/` — SQL migrations and the daily puzzle population script

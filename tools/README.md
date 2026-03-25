# Tools

Scripts for managing the quote database.

## import_quotes.py

Imports quotes from a JSON file or the Zen Quotes API into the database. Handles deduplication, encoding (letter + number substitution ciphers), difficulty classification, and author creation.

```bash
# Preview (no changes)
python3 tools/import_quotes.py --source "simple cryptogram/data/quotes.json" --preview

# Import from JSON
python3 tools/import_quotes.py --source "simple cryptogram/data/quotes.json" --import

# Import from Zen Quotes API
python3 tools/import_quotes.py --source zenquotes --preview --batches 5
```

New authors are inserted with name only — run `enrich_authors.py` to fill in biographical data.

**Requirements:** `pip install requests` (only for zenquotes source)

**JSON format:** `[{"author": "Name", "text": "Quote text"}, ...]`

## enrich_authors.py

Fills in biographical data (full name, birth/death dates, places, summary) for authors missing it, using the Claude API.

```bash
# See who needs enrichment
python3 tools/enrich_authors.py --preview

# Enrich all
python3 tools/enrich_authors.py --enrich

# Enrich specific authors
python3 tools/enrich_authors.py --enrich --authors "John Doe" "Jane Smith"
```

**Requirements:** `pip install anthropic` + `ANTHROPIC_API_KEY` env var

## generate_diagrams.py

Auto-generates Mermaid diagrams from Swift source code. Outputs to `docs/diagrams/`.

```bash
python3 tools/generate_diagrams.py
```

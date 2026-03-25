#!/usr/bin/env python3
"""
Author Enrichment for Simple Cryptogram
=========================================
Finds authors with missing biographical data and enriches them via Claude API.

Usage:
  # Preview which authors need enrichment
  python3 enrich_authors.py --preview

  # Enrich all authors missing summaries
  python3 enrich_authors.py --enrich

  # Enrich only specific authors by name
  python3 enrich_authors.py --enrich --authors "John Doe" "Jane Smith"

Requirements:
  pip install anthropic
  ANTHROPIC_API_KEY environment variable must be set
"""

import argparse
import json
import os
import re
import sqlite3
import sys

# --- Config ---
DB_PATH = os.path.join(os.path.dirname(__file__),
                       "..", "simple cryptogram", "data", "quotes.db")


def get_unenriched_authors(db_path):
    """Find authors missing biographical data (no summary)."""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("""
        SELECT name FROM authors
        WHERE summary IS NULL OR summary = ''
        ORDER BY name
    """)
    authors = [row[0] for row in c.fetchall()]
    conn.close()
    return authors


def enrich_authors(author_names, db_path):
    """Use Claude API to get biographical data and update the database."""
    try:
        import anthropic
    except ImportError:
        print("Error: 'anthropic' package required. Run: pip install anthropic")
        sys.exit(1)

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("Error: ANTHROPIC_API_KEY environment variable not set")
        sys.exit(1)

    client = anthropic.Anthropic()

    # Process in batches of 10
    batch_size = 10
    all_results = []

    for i in range(0, len(author_names), batch_size):
        batch = author_names[i:i + batch_size]
        print(f"  Enriching authors {i+1}-{i+len(batch)} of {len(author_names)}...",
              flush=True)

        names_list = "\n".join(f"- {name}" for name in batch)
        prompt = f"""For each of the following people, provide biographical information.
Return a JSON array with one object per person. Each object must have these exact fields:
- "name": the name as given (preserve exact spelling)
- "full_name": their full legal/birth name (or the name as given if unknown)
- "birth_date": in "YYYY-MM-DD" format, or "YYYY" if only year known, or null if unknown
- "death_date": in "YYYY-MM-DD" format, or null if still alive or unknown
- "place_of_birth": city, state/region, country (or null if unknown)
- "place_of_death": city, state/region, country (or null if still alive/unknown)
- "summary": 2-3 sentences about their significance and influence (factual, encyclopedic tone)

If an entry is not a person (e.g., a proverb source, religious text, or "Unknown"), set all
biographical fields to null and write an appropriate summary.

Return ONLY the JSON array, no markdown formatting or other text.

People:
{names_list}"""

        try:
            response = client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4096,
                messages=[{"role": "user", "content": prompt}]
            )
            text = response.content[0].text.strip()

            # Strip markdown code fences if present
            text = re.sub(r'^```(?:json)?\s*', '', text)
            text = re.sub(r'\s*```$', '', text)

            batch_data = json.loads(text)
            all_results.extend(batch_data)

            # Print what we got
            for author in batch_data:
                status = "alive" if author.get("death_date") is None else f"d. {author['death_date']}"
                birth = author.get("birth_date") or "?"
                print(f"    {author['name']}: b. {birth}, {status}")

        except json.JSONDecodeError as e:
            print(f"    Warning: Failed to parse response for batch: {e}")
            print(f"    Raw response: {text[:200]}...")
            for name in batch:
                all_results.append(None)
        except Exception as e:
            print(f"    Warning: API error for batch: {e}")
            for name in batch:
                all_results.append(None)

    # Update database
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    updated = 0
    skipped = 0

    for result in all_results:
        if result is None:
            skipped += 1
            continue
        try:
            c.execute("""
                UPDATE authors SET
                    full_name = COALESCE(?, full_name),
                    birth_date = COALESCE(?, birth_date),
                    death_date = COALESCE(?, death_date),
                    place_of_birth = COALESCE(?, place_of_birth),
                    place_of_death = COALESCE(?, place_of_death),
                    summary = COALESCE(?, summary)
                WHERE name = ?
            """, (
                result.get("full_name"),
                result.get("birth_date"),
                result.get("death_date"),
                result.get("place_of_birth"),
                result.get("place_of_death"),
                result.get("summary"),
                result["name"],
            ))
            if c.rowcount > 0:
                updated += 1
        except Exception as e:
            print(f"    Warning: Failed to update '{result.get('name')}': {e}")
            skipped += 1

    conn.commit()
    conn.close()
    print(f"\n  Updated: {updated} authors, Skipped: {skipped}")


def main():
    parser = argparse.ArgumentParser(description="Enrich author biographical data")
    parser.add_argument("--preview", action="store_true",
                        help="Show which authors need enrichment")
    parser.add_argument("--enrich", action="store_true",
                        help="Enrich authors via Claude API")
    parser.add_argument("--authors", nargs="+",
                        help="Specific author names to enrich (default: all unenriched)")
    args = parser.parse_args()

    if not args.preview and not args.enrich:
        parser.print_help()
        sys.exit(1)

    db_path = os.path.abspath(DB_PATH)
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}")
        sys.exit(1)

    if args.authors:
        author_names = args.authors
    else:
        author_names = get_unenriched_authors(db_path)

    if not author_names:
        print("All authors already have biographical data. Nothing to do.")
        return

    if args.preview:
        print(f"Authors needing enrichment ({len(author_names)}):")
        for name in author_names:
            print(f"  - {name}")
        return

    print(f"Enriching {len(author_names)} authors via Claude API...")
    enrich_authors(author_names, db_path)
    print("\nDone!")


if __name__ == "__main__":
    main()

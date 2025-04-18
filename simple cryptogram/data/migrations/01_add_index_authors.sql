-- Creates an index on authors.name for faster lookups
CREATE INDEX IF NOT EXISTS idx_authors_name ON authors(name);

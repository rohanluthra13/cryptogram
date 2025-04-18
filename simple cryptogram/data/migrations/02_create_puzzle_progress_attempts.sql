CREATE TABLE IF NOT EXISTS puzzle_progress_attempts (
    attempt_id TEXT PRIMARY KEY,
    puzzle_id TEXT NOT NULL,
    encoding_type TEXT NOT NULL,
    completed_at TEXT,
    failed_at TEXT,
    completion_time REAL,
    FOREIGN KEY (puzzle_id) REFERENCES quotes(id)
);

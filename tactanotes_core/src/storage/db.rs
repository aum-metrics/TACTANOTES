use rusqlite::{params, Connection, Result};
use super::security::Encryptor;

pub struct Database {
    conn: Connection,
    encryptor: Encryptor,
}

impl Database {
    pub fn open(path: &str, password: &str) -> Result<Self> {
        let conn = Connection::open(path)?;
        let encryptor = Encryptor::new(password);
        
        // Feature F5: Optimization - WAL Mode
        conn.execute("PRAGMA journal_mode=WAL;", [])?;
        conn.execute("PRAGMA synchronous=NORMAL;", [])?;
        
        // Feature F8: Academic Hierarchy (Schema)
        conn.execute(
            "CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY,
                title TEXT,
                content TEXT,
                tags TEXT,
                created_at INTEGER,
                updated_at INTEGER,
                is_deleted INTEGER DEFAULT 0
            )",
            [],
        )?;
        
        // Feature F1: Streaming ASR Audio Chunks storage
        conn.execute(
            "CREATE TABLE IF NOT EXISTS audio_chunks (
                id INTEGER PRIMARY KEY,
                note_id INTEGER,
                data BLOB,
                duration_ms INTEGER,
                created_at INTEGER
            )",
            [],
        )?;

        // Feature F16: "Zen Search" (Full Text Search)
        // We use a virtual table to index titles and plain-text summaries (decrypted cache)
        conn.execute(
            "CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(title, content, content_rowid='notes_id')",
            [],
        )?;

        Ok(Self { conn, encryptor })
    }

    pub fn add_note(&self, title: &str, content: &str) -> Result<i64> {
        // Encrypt content (F14)
        let encrypted_content = self.encryptor.encrypt(content.as_bytes())
            .map_err(|_| rusqlite::Error::ToSqlConversionFailure("Encryption Error".into()))?;
            
        // For title, we might keep plain for search or encrypt too. Keeping plain for MVP search.
        
        self.conn.execute(
            "INSERT INTO notes (title, content, created_at, updated_at) VALUES (?1, ?2, ?3, ?3)",
            params![title, encrypted_content, chrono::Utc::now().timestamp()],
        )?;
        Ok(self.conn.last_insert_rowid())
    }

    // F09: Cloud Delta Sync (Get Changes)
    pub fn get_modified_notes(&self, since: i64) -> Result<Vec<(i64, String, Vec<u8>, i64)>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, content, updated_at FROM notes WHERE updated_at > ?1"
        )?;
        
        let rows = stmt.query_map([since], |row| {
             Ok((
                row.get(0)?, // id
                row.get(1)?, // title
                row.get(2)?, // content (blob/encrypted)
                row.get(3)?, // updated_at
            ))           
        })?;

        let mut results = Vec::new();
        for row in rows {
            results.push(row?);
        }
        Ok(results)
    }

    pub fn search_notes(&self, _query: &str) -> Result<Vec<(String, String)>> {
        // F13: Placeholder for FTS5 search
        Ok(Vec::new())
    }
}

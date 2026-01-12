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
}

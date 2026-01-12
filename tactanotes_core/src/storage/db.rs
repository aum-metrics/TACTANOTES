#[cfg(not(target_arch = "wasm32"))]
mod real {
    use rusqlite::{params, Connection, Result};
    use crate::storage::security::Encryptor;

    pub struct Database {
        conn: Connection,
        encryptor: Encryptor,
    }

    impl Database {
        pub fn open(path: &str, password: &str) -> Result<Self> {
            let conn = Connection::open(path)?;
            let encryptor = Encryptor::new(password);
            
            // Feature F5: Optimization - WAL Mode
            // PRAGMA journal_mode returns the new mode, so we must consume it to avoid ExecuteReturnedResults error
            let _mode: String = conn.query_row("PRAGMA journal_mode=WAL;", [], |row| row.get(0))?;
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

            // Folder Support
            conn.execute(
                "CREATE TABLE IF NOT EXISTS folders (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    created_at INTEGER
                )",
                [],
            )?;

            // Attachments Support
            conn.execute(
                "CREATE TABLE IF NOT EXISTS attachments (
                    id INTEGER PRIMARY KEY,
                    note_id INTEGER,
                    file_type TEXT,
                    file_path TEXT,
                    created_at INTEGER
                )",
                [],
            )?;

            // Migration: Add folder_id to notes if missing
            // This is a naive check; production would use proper migration versioning (e.g., user_version pragma)
            let _ = conn.execute("ALTER TABLE notes ADD COLUMN folder_id INTEGER DEFAULT NULL", []);

            Ok(Self { conn, encryptor })
        }

        pub fn add_note(&self, title: &str, content: &str, folder_id: Option<i64>) -> Result<i64> {
            // Encrypt content (F14)
            let encrypted_content = self.encryptor.encrypt(content.as_bytes())
                .map_err(|_| rusqlite::Error::ToSqlConversionFailure("Encryption Error".into()))?;
                
            self.conn.execute(
                "INSERT INTO notes (title, content, created_at, updated_at, folder_id) VALUES (?1, ?2, ?3, ?3, ?4)",
                params![title, encrypted_content, chrono::Utc::now().timestamp(), folder_id],
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

        pub fn create_folder(&self, name: &str) -> Result<i64> {
            self.conn.execute(
                "INSERT INTO folders (name, created_at) VALUES (?1, ?2)",
                params![name, chrono::Utc::now().timestamp()],
            )?;
            Ok(self.conn.last_insert_rowid())
        }

        pub fn get_folders(&self) -> Result<Vec<(i64, String)>> {
            let mut stmt = self.conn.prepare("SELECT id, name FROM folders ORDER BY name ASC")?;
            let rows = stmt.query_map([], |row| {
                Ok((row.get(0)?, row.get(1)?))
            })?;
            let mut results = Vec::new();
            for row in rows {
                results.push(row?);
            }
            Ok(results)
        }

        pub fn get_notes_by_folder(&self, folder_id: i64) -> Result<Vec<(i64, String, String, i64)>> {
            let mut stmt = self.conn.prepare("SELECT id, title, content, updated_at FROM notes WHERE folder_id = ?1 ORDER BY updated_at DESC")?;
            let rows = stmt.query_map([folder_id], |row| {
                 Ok((
                    row.get(0)?,
                    row.get(1)?,
                    String::from_utf8(self.encryptor.decrypt(&row.get::<_, Vec<u8>>(2)?).unwrap_or(b"Decryption Failed".to_vec())).unwrap_or_default(),
                    row.get(3)?,
                ))
            })?;
            let mut results = Vec::new();
            for row in rows {
                results.push(row?);
            }
            Ok(results)
        }

        pub fn update_note(&self, note_id: i64, title: &str, content: &str) -> Result<()> {
            // Encrypt content
            let encrypted_content = self.encryptor.encrypt(content.as_bytes())
                .map_err(|_| rusqlite::Error::ToSqlConversionFailure("Encryption Error".into()))?;
            
            self.conn.execute(
                "UPDATE notes SET title = ?1, content = ?2, updated_at = ?3 WHERE id = ?4",
                params![title, encrypted_content, chrono::Utc::now().timestamp(), note_id],
            )?;
            Ok(())
        }

        pub fn delete_note(&self, note_id: i64) -> Result<()> {
            // Soft delete by setting is_deleted flag
            self.conn.execute(
                "UPDATE notes SET is_deleted = 1, updated_at = ?1 WHERE id = ?2",
                params![chrono::Utc::now().timestamp(), note_id],
            )?;
            Ok(())
        }

        pub fn get_note(&self, note_id: i64) -> Result<(i64, String, String, i64)> {
            self.conn.query_row(
                "SELECT id, title, content, updated_at FROM notes WHERE id = ?1 AND is_deleted = 0",
                params![note_id],
                |row| {
                    Ok((
                        row.get(0)?,
                        row.get(1)?,
                        String::from_utf8(self.encryptor.decrypt(&row.get::<_, Vec<u8>>(2)?).unwrap_or(b"Decryption Failed".to_vec())).unwrap_or_default(),
                        row.get(3)?,
                    ))
                },
            )
        }

        pub fn add_attachment(&self, note_id: i64, file_type: &str, file_path: &str) -> Result<i64> {
            self.conn.execute(
                "INSERT INTO attachments (note_id, file_type, file_path, created_at) VALUES (?1, ?2, ?3, ?4)",
                params![note_id, file_type, file_path, chrono::Utc::now().timestamp()],
            )?;
            Ok(self.conn.last_insert_rowid())
        }

        pub fn get_attachments(&self, note_id: i64) -> Result<Vec<(i64, String, String)>> {
            let mut stmt = self.conn.prepare("SELECT id, file_type, file_path FROM attachments WHERE note_id = ?1")?;
            let rows = stmt.query_map([note_id], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?;
            let mut results = Vec::new();
            for row in rows {
                results.push(row?);
            }
            Ok(results)
        }
    }
}


#[cfg(not(target_arch = "wasm32"))]
pub use real::Database;

#[cfg(target_arch = "wasm32")]
mod mock {
    pub struct Database;

    impl Database {
        pub fn open(_path: &str, _password: &str) -> anyhow::Result<Self> {
            Ok(Self)
        }

        // Use a generic result or matching error type if possible, but anyhow is safer for stub
        pub fn add_note(&self, _title: &str, _content: &str, _folder_id: Option<i64>) -> anyhow::Result<i64> {
            Ok(1)
        }

        pub fn get_modified_notes(&self, _since: i64) -> anyhow::Result<Vec<(i64, String, Vec<u8>, i64)>> {
            Ok(Vec::new())
        }

        pub fn search_notes(&self, _query: &str) -> anyhow::Result<Vec<(String, String)>> {
            Ok(Vec::new())
        }

        pub fn create_folder(&self, _name: &str) -> anyhow::Result<i64> {
            Ok(1)
        }

        pub fn get_folders(&self) -> anyhow::Result<Vec<(i64, String)>> {
            Ok(vec![(1, "General".to_string())])
        }

        pub fn assign_note_to_folder(&self, _note_id: i64, _folder_id: i64) -> anyhow::Result<()> {
            Ok(())
        }

        pub fn get_notes_by_folder(&self, _folder_id: i64) -> anyhow::Result<Vec<(i64, String, String, i64)>> {
             Ok(Vec::new())
        }

        pub fn update_note(&self, _note_id: i64, _title: &str, _content: &str) -> anyhow::Result<()> {
            Ok(())
        }

        pub fn delete_note(&self, _note_id: i64) -> anyhow::Result<()> {
            Ok(())
        }

        pub fn get_note(&self, _note_id: i64) -> anyhow::Result<(i64, String, String, i64)> {
            Ok((1, "Mock".to_string(), "Content".to_string(), 0))
        }

        pub fn add_attachment(&self, _note_id: i64, _type: &str, _path: &str) -> anyhow::Result<i64> {
            Ok(1)
        }

        pub fn get_attachments(&self, _note_id: i64) -> anyhow::Result<Vec<(i64, String, String)>> {
            Ok(Vec::new())
        }
    }
}

#[cfg(target_arch = "wasm32")]
pub use mock::Database;

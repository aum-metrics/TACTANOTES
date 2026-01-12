// Feature F09: Cloud Delta Sync
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct SyncBlob {
    pub version: u32,
    pub timestamp: i64,
    pub changes: Vec<NoteDelta>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NoteDelta {
    pub id: i64,
    pub title: String,
    pub encrypted_content: Vec<u8>,
    pub updated_at: i64,
}

pub struct SyncEngine;

impl SyncEngine {
    pub fn new() -> Self {
        Self {}
    }

    // "Packing" Logic (Encryption + Serialization)
    // Takes raw modified rows from DB and creates a transport-ready BLOB
    pub fn pack_delta(notes: Vec<(i64, String, Vec<u8>, i64)>) -> Result<Vec<u8>, serde_json::Error> {
        let deltas: Vec<NoteDelta> = notes.into_iter().map(|(id, title, encrypted_content, updated_at)| {
            NoteDelta {
                id,
                title,
                encrypted_content,
                updated_at
            }
        }).collect();

        let blob = SyncBlob {
            version: 1,
            timestamp: chrono::Utc::now().timestamp(),
            changes: deltas,
        };

        // Serialize to generic binary (JSON for MVP, Protobuf for Prod)
        serde_json::to_vec(&blob)
    }
}

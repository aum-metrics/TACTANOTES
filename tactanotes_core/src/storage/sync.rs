use std::collections::HashMap;

// Feature F7: Delta-Cloud Sync
// Simulates binary diffing

#[derive(Debug, Clone)]
pub struct NoteState {
    pub id: i64,
    pub content_hash: String,
    pub updated_at: i64,
}

pub struct SyncEngine {
    // Determine what needs to be uploaded/downloaded
}

impl SyncEngine {
    pub fn new() -> Self {
        Self {}
    }

    pub fn calculate_changes(
        local_notes: &[NoteState],
        remote_notes: &[NoteState]
    ) -> (Vec<i64>, Vec<i64>) {
        // Returns (ToUpload, ToDownload)
        let mut to_upload = Vec::new();
        let mut to_download = Vec::new();
        
        let remote_map: HashMap<i64, &NoteState> = remote_notes.iter().map(|n| (n.id, n)).collect();
        
        for local in local_notes {
            if let Some(remote) = remote_map.get(&local.id) {
                if local.updated_at > remote.updated_at {
                    to_upload.push(local.id);
                } else if remote.updated_at > local.updated_at {
                    to_download.push(local.id); // Conflict resolution: Server wins (simplified)
                }
            } else {
                // New local note
                to_upload.push(local.id);
            }
        }
        
        // Check for new remote notes
        let local_ids: Vec<i64> = local_notes.iter().map(|n| n.id).collect();
        for remote in remote_notes {
            if !local_ids.contains(&remote.id) {
                to_download.push(remote.id);
            }
        }

        (to_upload, to_download)
    }
}

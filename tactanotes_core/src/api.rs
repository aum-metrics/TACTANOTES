use std::sync::Mutex;
// use lazy_static::lazy_static; // Ensure this is in Cargo.toml or use std::sync::OnceLock if rust 1.70+
use crate::engine::Engine;

// Global Engine Instance
// In a real production app, consider using `RustOpaque` or a proper dependency injection
// but for this hybrid architecture, a global Mutex is standard for the singleton Engine.
lazy_static::lazy_static! {
    static ref ENGINE: Mutex<Option<Engine>> = Mutex::new(None);
}

fn get_engine<F, R>(f: F) -> anyhow::Result<R>
where
    F: FnOnce(&mut Engine) -> anyhow::Result<R>,
{
    let mut lock = ENGINE.lock().unwrap();
    if let Some(ref mut engine) = *lock {
        f(engine)
    } else {
        Err(anyhow::anyhow!("Rust Engine not initialized. Call init_app first."))
    }
}

pub fn init_app(db_path: String, models_dir: String) -> anyhow::Result<()> {
    let mut lock = ENGINE.lock().unwrap();
    if lock.is_none() {
        println!("Rust: Initializing Engine with DB at {} and Models at {}", db_path, models_dir);
        // Ensure parent directory exists
        if let Some(parent) = std::path::Path::new(&db_path).parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        let engine = Engine::new(&db_path, &models_dir);
        
        // Seed a default folder if none exist (F8: Academic Hierarchy)
        if let Ok(folders) = engine.get_folders() {
            if folders.is_empty() {
                println!("Rust: Seeding initial 'General' folder...");
                let _ = engine.create_folder("General");
            }
        }

        *lock = Some(engine);
        println!("Rust: App Initialized Successfully.");
    }
    Ok(())
}

pub fn start_recording(subject: String) -> anyhow::Result<()> {
    get_engine(|engine| {
        engine.set_subject(&subject);
        engine.start_recording()
    })
}

pub fn stop_recording(append_to: Option<i64>) -> anyhow::Result<String> {
    get_engine(|engine| {
        Ok(engine.stop_recording_and_summarize(append_to))
    })
}

// Gap 5: Thermal Update from Flutter
pub fn update_thermal_status(battery_temp: f32) {
    let _ = get_engine(|engine| {
        engine.update_battery_temp(battery_temp);
        Ok(())
    });
}

pub fn create_folder(name: String) -> anyhow::Result<i64> {
    get_engine(|engine| {
        engine.create_folder(&name)
    })
}

pub fn get_folders() -> anyhow::Result<Vec<(i64, String)>> {
    get_engine(|engine| {
        engine.get_folders()
    })
}

pub fn get_notes_by_folder(folder_id: i64) -> anyhow::Result<Vec<(i64, String, String, i64)>> {
    get_engine(|engine| {
        engine.get_notes_by_folder(folder_id)
    })
}

pub fn set_current_folder(folder_id: Option<i64>) -> anyhow::Result<()> {
    get_engine(|engine| {
        engine.set_current_folder(folder_id);
        Ok(())
    })
}

pub fn add_note(title: String, content: String, folder_id: Option<i64>) -> anyhow::Result<i64> {
    get_engine(|engine| {
        engine.add_note(&title, &content, folder_id)
    })
}

pub fn update_note(note_id: i64, title: String, content: String) -> anyhow::Result<()> {
    get_engine(|engine| {
        engine.update_note(note_id, &title, &content)
    })
}

pub fn delete_note(note_id: i64) -> anyhow::Result<()> {
    get_engine(|engine| {
        engine.delete_note(note_id)
    })
}

pub fn get_current_transcript() -> anyhow::Result<String> {
    get_engine(|engine| {
        engine.tick(); // Process pending audio
        Ok(engine.get_current_transcript())
    })
}

pub fn get_note(note_id: i64) -> anyhow::Result<(i64, String, String, i64)> {
    get_engine(|engine| {
        engine.get_note(note_id)
    })
}

pub fn get_attachments(note_id: i64) -> anyhow::Result<Vec<(i64, String, String)>> {
    get_engine(|engine| {
        engine.get_attachments(note_id)
    })
}

pub fn add_attachment(note_id: i64, file_type: String, file_path: String) -> anyhow::Result<i64> {
    get_engine(|engine| {
        engine.add_attachment(note_id, &file_type, &file_path)
    })
}


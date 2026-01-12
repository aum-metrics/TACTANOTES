use std::sync::Mutex;
// use lazy_static::lazy_static; // Ensure this is in Cargo.toml or use std::sync::OnceLock if rust 1.70+
use crate::engine::Engine;

// Global Engine Instance
// In a real production app, consider using `RustOpaque` or a proper dependency injection
// but for this hybrid architecture, a global Mutex is standard for the singleton Engine.
lazy_static::lazy_static! {
    static ref ENGINE: Mutex<Engine> = Mutex::new(Engine::new());
}

#[no_mangle]
pub extern "C" fn init_app() {
    let _guard = ENGINE.lock().unwrap();
    println!("App Initialized");
}

pub fn start_recording(subject: String) -> anyhow::Result<()> {
    let mut engine = ENGINE.lock().unwrap();
    engine.set_subject(&subject);
    engine.start_recording()
}

pub fn stop_recording() -> anyhow::Result<String> {
    let mut engine = ENGINE.lock().unwrap();
    Ok(engine.stop_recording_and_summarize())
}

// Gap 5: Thermal Update from Flutter
pub fn update_thermal_status(battery_temp: f32) {
    let mut engine = ENGINE.lock().unwrap();
    engine.update_battery_temp(battery_temp);
}

pub fn create_folder(name: String) -> anyhow::Result<i64> {
    let engine = ENGINE.lock().unwrap();
    engine.create_folder(&name)
}

pub fn get_folders() -> anyhow::Result<Vec<(i64, String)>> {
    let engine = ENGINE.lock().unwrap();
    engine.get_folders()
}

pub fn get_notes_by_folder(folder_id: i64) -> anyhow::Result<Vec<(i64, String, String, i64)>> {
    let engine = ENGINE.lock().unwrap();
    engine.get_notes_by_folder(folder_id)
}

pub fn set_current_folder(folder_id: Option<i64>) -> anyhow::Result<()> {
    let mut engine = ENGINE.lock().unwrap();
    engine.set_current_folder(folder_id);
    Ok(())
}

use std::sync::Mutex;
use lazy_static::lazy_static; // Ensure this is in Cargo.toml or use std::sync::OnceLock if rust 1.70+
use crate::engine::Engine;

// Global Engine Instance
// In a real production app, consider using `RustOpaque` or a proper dependency injection
// but for this hybrid architecture, a global Mutex is standard for the singleton Engine.
lazy_static::lazy_static! {
    static ref ENGINE: Mutex<Engine> = Mutex::new(Engine::new());
}

pub fn init_app() -> String {
    // Force init
    let _ = ENGINE.lock().unwrap();
    "Tactanotes Core v5.3 Initialized".to_string()
}

pub fn start_recording(subject: String) -> anyhow::Result<()> {
    let mut engine = ENGINE.lock().unwrap();
    engine.set_subject(&subject);
    engine.start_recording()
}

pub fn stop_recording() {
    let mut engine = ENGINE.lock().unwrap();
    engine.stop_recording_and_summarize();
}

// Gap 5: Thermal Update from Flutter
pub fn update_thermal_status(battery_temp: f32) {
    let mut engine = ENGINE.lock().unwrap();
    engine.update_battery_temp(battery_temp);
}

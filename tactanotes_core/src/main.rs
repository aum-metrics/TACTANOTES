use tactanotes_core::engine::Engine;
use std::thread;
use std::time::Duration;
use std::io::{self, Write};

fn main() {
    println!(">>> TACTANOTES v5.3 CORE KERNEL <<<");
    println!("Mode: Standalone CLI (Endurance Test)");
    println!("Spec: 10-Hour Survival / 900MB Cap");
    println!("-------------------------------------");

    let mut engine = Engine::new("tactanotes_cli.db", "../tactanotes_ui/assets/models");
    
    // Set Subject
    engine.set_subject("CLI_Session_001");
    
    // Start Recording
    match engine.start_recording() {
        Ok(_) => println!("✅ Audio Capture Started (CPAL)"),
        Err(e) => {
            eprintln!("❌ Failed to start audio: {}", e);
            return;
        }
    }

    println!("Running... Press Ctrl+C to stop.");
    println!("(Logs will appear below for State B flushes and Endurance checks)");

    // Main Event Loop
    // Simulates the UI thread tick
    let mut tick_counter: u64 = 0;
    loop {
        engine.tick();
        tick_counter += 1;
        
        // Sleep to simulate ~10Hz tick rate
        thread::sleep(Duration::from_millis(100));
        
        // Every 30 seconds, print a heartbeat
        if tick_counter % 300 == 0 {
             print!(".");
             io::stdout().flush().unwrap();
        }
    }
}

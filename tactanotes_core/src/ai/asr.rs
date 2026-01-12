// Feature F1: Streaming ASR
// Uses Whisper-Tiny (GGML) via whisper-rs bindings
use whisper_rs::{WhisperContext, WhisperContextParameters, FullParams, SamplingStrategy};
use std::path::Path;

pub struct WhisperModel {
    ctx: Option<WhisperContext>,
    // We create state on the fly or cache it. For simplicity in this architectural phase, we wrap context.
    // Ideally, we'd cache WhisperState for performance, but it requires self-referential structs or unsafe/Arc.
    // V5.4: We re-create state per transcribe to be safe/simple.
}

impl WhisperModel {
    pub fn load() -> Self {
        println!("Loading Whisper-Tiny (ggml-tiny.en.bin)...");
        
        // Path resolution: Try multiple likely locations
        let paths = [
            "../tactanotes_ui/assets/models/ggml-tiny.en.bin", // Dev (Core root)
            "assets/models/ggml-tiny.en.bin",                  // Prod (UI root)
            "/Users/sambath/Documents/CODE/coding/TACTANOTES/tactanotes_ui/assets/models/ggml-tiny.en.bin" // Abs fallback
        ];
        
        for path_str in paths.iter() {
            let path = Path::new(path_str);
            if path.exists() {
                 println!("Found model at: {:?}", path);
                 let ctx_params = WhisperContextParameters::default();
                 match WhisperContext::new_with_params(path_str, ctx_params) {
                     Ok(ctx) => {
                         println!("Whisper Engine Loaded Successfully.");
                         return Self { ctx: Some(ctx) };
                     },
                     Err(e) => {
                         println!("Failed to load Whisper context: {:?}", e);
                     }
                 }
            }
        }
        
        println!("ERROR: GGML Model not found in any standard path.");
        Self { ctx: None }
    }

    pub fn transcribe(&self, audio_chunk: &[f32]) -> String {
        if let Some(ctx) = &self.ctx {
            // 1. Create State
            let mut state = match ctx.create_state() {
                Ok(s) => s,
                Err(e) => {
                    println!("Failed to create Whisper state: {:?}", e);
                    return String::new();
                }
            };
            
            // 2. Configure Params
            let mut params = FullParams::new(SamplingStrategy::Greedy { best_of: 1 });
            params.set_n_threads(2); // Keep low for Endurance
            params.set_language(Some("en"));
            params.set_print_special(false);
            params.set_print_progress(false);
            params.set_print_realtime(false);
            params.set_print_timestamps(false);

            // 3. Run Inference
            if let Err(e) = state.full(params, audio_chunk) {
                println!("Whisper Inference Failed: {:?}", e);
                return String::new();
            }

            // 4. Collect Text
            let num_segments = state.full_n_segments().unwrap_or(0);
            let mut full_text = String::new();
            
            for i in 0..num_segments {
                if let Ok(segment) = state.full_get_segment_text(i) {
                    full_text.push_str(&segment);
                    full_text.push(' ');
                }
            }
            
            return full_text.trim().to_string();
        }
        
        String::new()
    }
}

impl Drop for WhisperModel {
    fn drop(&mut self) {
        println!("Unloading Whisper Engine...");
        // whisper-rs handles drop/free via FFI
    }
}

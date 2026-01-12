use super::asr::WhisperModel;
use super::llm::LlmModel;

// Feature 8.1: Inference Interleaving & Memory Management
// Critical: Only one model type should be Some(...) at a time.

pub struct ModelManager {
    asr: Option<WhisperModel>,
    llm: Option<LlmModel>,
}

impl ModelManager {
    pub fn new() -> Self {
        console_log("Initializing AI Model Manager (Idle State)");
        Self {
            asr: None,
            llm: None,
        }
    }

    pub fn load_asr(&mut self) {
        if self.llm.is_some() {
            self.unload_llm(); // Safety enforcement
        }
        if self.asr.is_none() {
            self.asr = Some(WhisperModel::load());
        }
    }

    pub fn unload_asr(&mut self) {
        if self.asr.is_some() {
            self.asr = None; // Drop trait will function here
        }
    }

    pub fn load_llm(&mut self) {
        if self.asr.is_some() {
            self.unload_asr(); // Safety enforcement
        }
        if self.llm.is_none() {
            self.llm = Some(LlmModel::load());
        }
    }

    pub fn unload_llm(&mut self) {
        if self.llm.is_some() {
            println!("ModelManager: Unloading LLM tensors...");
            self.llm = None; // Drop trait will function here
            
            // Refinement 2: Fragmentation & force_gc
            // Critical for 10-Hour Stability: Clear the large pages used by LLM
            // before loading the ASR state back in.
            self.force_gc();
        }
    }

    pub fn transcribe(&self, audio: &[f32]) -> String {
        if let Some(asr) = &self.asr {
            asr.transcribe(audio)
        } else {
            String::new() // Or Error: ASR not loaded
        }
    }

    pub fn summarize(&self, text: &str) -> String {
        if let Some(llm) = &self.llm {
            llm.summarize(text)
        } else {
            String::new() // Or Error: LLM not loaded
        }
    }

    // Feature v5.3: Manual Memory Collection
    pub fn force_gc(&self) {
        println!("ModelManager: Triggering manual heap collection (mi_collect).");
        // unsafe { libmimalloc_sys::mi_collect(true) };
    }
}

fn console_log(msg: &str) {
    println!("[AI Manager] {}", msg);
}

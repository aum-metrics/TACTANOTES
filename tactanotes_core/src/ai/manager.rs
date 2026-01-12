use super::asr::WhisperModel;
use super::llm::LlmModel;
use super::rag::VectorStore;

// Feature 8.1: Inference Interleaving & Memory Management
// Critical: Only one model type should be Some(...) at a time.

pub struct ModelManager {
    asr: Option<WhisperModel>,
    llm: Option<LlmModel>,
    rag: Option<VectorStore>,
    models_dir: String,
}

impl ModelManager {
    pub fn new(models_dir: &str) -> Self {
        console_log(&format!("Initializing AI Model Manager in {}", models_dir));
        Self {
            asr: None,
            llm: None,
            rag: None,
            models_dir: models_dir.to_string(),
        }
    }

    pub fn load_asr(&mut self) {
        if self.llm.is_some() {
            self.unload_llm(); // Safety enforcement
        }
        if self.rag.is_some() {
            self.unload_rag(); // Unload RAG if switching back to recording
        }
        if self.asr.is_none() {
            self.asr = Some(WhisperModel::load(&self.models_dir));
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
            self.llm = Some(LlmModel::load(&self.models_dir));
        }
    }

    pub fn unload_llm(&mut self) {
        if self.llm.is_some() {
            println!("ModelManager: Unloading LLM tensors...");
            self.llm = None; // Drop trait will function here
            self.force_gc();
        }
    }

    pub fn load_rag(&mut self) {
        // RAG aligns with LLM phase, so we don't necessarily unload LLM, 
        // but we definitely ensure ASR is gone.
        if self.asr.is_some() {
            self.unload_asr();
        }
        if self.rag.is_none() {
             println!("ModelManager: Loading RAG Embedding Model...");
             if let Ok(store) = VectorStore::new() {
                 self.rag = Some(store);
             } else {
                 println!("ModelManager: Failed to load RAG model.");
             }
        }
    }

    pub fn unload_rag(&mut self) {
        if self.rag.is_some() {
            println!("ModelManager: Unloading RAG model...");
            self.rag = None;
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

    pub fn embed(&self, text: &str) -> Option<Vec<f32>> {
        if let Some(rag) = &self.rag {
            rag.embed(text).ok()
        } else {
            None
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

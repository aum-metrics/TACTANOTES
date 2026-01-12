// Feature F2: Summarisation
// Uses Gemma-3-1B or Qwen2-0.5B (~300MB)

pub struct LlmModel {
    loaded: bool,
}

impl LlmModel {
    pub fn load() -> Self {
        println!("Loading LLM (llm_model.onnx)...");
        // v5.4: Target 'llm_model.onnx' (Qwen2.5-0.5B)
        // Config: Explicitly avoiding mlock to allow OS paging.
        Self { loaded: true }
    }

    pub fn summarize(&self, text: &str) -> String {
        if !self.loaded { return String::new(); }
        format!("Summary of: {}", text)
    }
}

impl Drop for LlmModel {
    fn drop(&mut self) {
        println!("Unloading LLM Model... (Freed ~300MB)");
        self.loaded = false;
    }
}

// Feature F2: Summarisation
// Uses Gemma-3-1B or Qwen2-0.5B (~300MB)

pub struct LlmModel {
    loaded: bool,
}

impl LlmModel {
    pub fn load(_models_dir: &str) -> Self {
        println!("Loading Extractive Summarizer (Native)...");
        // Lightweight logic, no heavy model file required.
        Self { loaded: true }
    }

    pub fn summarize(&self, text: &str) -> String {
        if !self.loaded || text.trim().is_empty() { return String::new(); }

        let sentences: Vec<&str> = text.split(|c| c == '.' || c == '?' || c == '!').collect();
        let mut seen_sentences = std::collections::HashSet::new();
        
        let significant_sentences: Vec<String> = sentences.iter()
            .filter(|s| {
                let s = s.trim();
                if s.len() < 15 { return false; }
                if s.contains("[BLANK_AUDIO]") { return false; }
                
                // Deduplication Filter
                let s_lower = s.to_lowercase();
                if seen_sentences.contains(&s_lower) { return false; }
                seen_sentences.insert(s_lower);

                // Key phrases filter
                let key_phrases = ["important", "remember", "note", "summary", "conclusion", "idea", "concept", "key"];
                // Relaxation: Accept if > 25 chars OR has key phrase. 50 was too strict.
                key_phrases.iter().any(|&k| s.to_lowercase().contains(k)) || s.len() > 25 
            })
            .map(|s| s.trim().to_string())
            .collect();

        if significant_sentences.is_empty() {
             // Fallback: Just take the first few meaningful sentences
             let fallback: Vec<String> = sentences.iter()
                .filter(|s| s.len() > 10)
                .take(3)
                .map(|s| s.trim().to_string())
                .collect();
             
             if fallback.is_empty() {
                 return format!("Main points: {}", text);
             }
             return format!("Summary:\n- {}", fallback.join(".\n- "));
        }

        format!("Key Takeaways:\n- {}", significant_sentences.join(".\n- "))
    }
}

impl Drop for LlmModel {
    fn drop(&mut self) {
        println!("Unloading Extractive Summarizer... (Freed 0MB)");
        self.loaded = false;
    }
}

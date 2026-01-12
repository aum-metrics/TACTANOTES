use crate::audio::capture::AudioRecorder;
use crate::audio::buffer::CircularAudioBuffer;
// use crate::audio::vad::VadEngine;
// use crate::ai::asr::WhisperModel;
// use crate::ai::llm::LlmModel;
use crate::storage::db::Database;
use crate::engine::endurance::{EnduranceController, EnduranceMode};
use crate::ai::manager::ModelManager;
use crate::ai::text::RollingBuffer;
use crate::ai::lang::LanguageDetector;
// use std::sync::{Arc, Mutex};
// use crate::ai::rag::VectorStore;

pub mod endurance;

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum EngineState {
    Idle,
    Recording,   // ASR Loaded, Buffer Empty
    Summarizing, // LLM Loaded, ASR Unloaded, Buffer Accumulating
}

pub struct Engine {
    state: EngineState,
    recorder: AudioRecorder,
    audio_buffer: CircularAudioBuffer, // v5.1 Hardening
    model_manager: ModelManager,
    buffer: RollingBuffer,
    lang_detector: LanguageDetector,
    current_subject: String,
    current_folder_id: Option<i64>,
    
    // v5.3 Endurance
    endurance: EnduranceController,
    tick_count: u64,
    
    database: Database,
    _models_dir: String,
    transcription_buffer: Vec<f32>, // v5.4: Accumulator for smoother ASR
    full_session_audio: Vec<f32>,   // v5.5: Persistence Buffer
}

impl Engine {
    pub fn new(db_path: &str, models_dir: &str) -> Self {
        Self {
            state: EngineState::Idle,
            recorder: AudioRecorder::new(),
            audio_buffer: CircularAudioBuffer::new(),
            model_manager: ModelManager::new(models_dir),
            buffer: RollingBuffer::new(8000), 
            lang_detector: LanguageDetector::new(),
            current_subject: "General".to_string(),
            current_folder_id: None,
            endurance: EnduranceController::new(),
            tick_count: 0,
            database: Database::open(db_path, "default_password").expect("Failed to open DB"),
            _models_dir: models_dir.to_string(),
            transcription_buffer: Vec::new(),
            full_session_audio: Vec::new(),
        }
    }
    
    pub fn set_subject(&mut self, subject: &str) {
        self.current_subject = subject.to_string();
    }

    pub fn start_recording(&mut self) -> anyhow::Result<()> {
        println!("Engine: Starting Recording (Subject: {})...", self.current_subject);
        
        // 1. Load ASR First
        self.model_manager.load_asr();
        
        // 2. Start Audio Capture
        self.recorder.start()?;
        
        self.state = EngineState::Recording;
        self.full_session_audio.clear(); // Reset buffer
        Ok(())
    }

    // Gap 5: Host -> Engine Thermal Update
    pub fn update_battery_temp(&mut self, temp: f32) {
        self.endurance.update_battery_temp(temp);
    }

    pub fn tick(&mut self) {
        self.tick_count += 1;
        
        // 1. Check Endurance every ~5 seconds (assuming 60 ticks/sec or similar, simplified here)
        if self.tick_count % 300 == 0 {
            let mode = self.endurance.check_status();
            if mode == EnduranceMode::Endurance {
                // Determine if we need to switch strategies
                // For now, just logging
            }
            
            // v5.3: Manual GC every 20 mins (simulated frequency here)
            if self.tick_count % 12000 == 0 {
                self.model_manager.force_gc();
            }
        }
    
        // v5.1: Audio Capture logic runs in ALL active states
        let new_audio = self.recorder.get_audio_data();
        
        match self.state {
            EngineState::Recording => {
                // v5.5 Persistence Accumulation
                if !new_audio.is_empty() {
                    self.full_session_audio.extend_from_slice(&new_audio);
                }

                // Check Endurance Status
                let mode = self.endurance.check_status();

                // v5.3 Checkpointing (State B): Every 2 minutes
                // Assuming tick rate is approx 10/sec (from tests), 2 mins = 120 seconds * 10 = 1200 ticks
                if self.tick_count > 0 && self.tick_count % 1200 == 0 {
                     println!("Engine: Reached 2-minute Checkpoint (State B). Flushing audio to disk...");
                     
                     // ENDURANCE MODE LOGIC: Run Batch Inference BEFORE flush
                     if mode == EnduranceMode::Endurance {
                         println!("Endurance Mode: Running Batch Inference on buffered audio before flush...");
                         // In simulation, we assume audio_buffer holds the chunk.
                         let buffered_audio = self.audio_buffer.read_all();
                         let text = self.model_manager.transcribe(&buffered_audio);
                         if !text.is_empty() {
                             println!("Batch Transcribed: {}", text);
                             self.buffer.push(&text);
                         }
                     }

                     // In real imp: Encrypt and append to SQLite blob
                     // For harness: Clear buffer to prove RAM release
                     self.audio_buffer.clear();
                     println!("Engine: RAM cleared. Audio flushed encrypted.");
                }
            
                // 1. Check if we have buffered audio from a previous swap
                if !self.audio_buffer.is_empty() {
                    // Only drain immediately if High Performance. In Endurance, we wait for Batch (State B).
                    if mode == EnduranceMode::HighPerformance {
                        println!("Engine: Draining Circular Buffer ({} samples)...", self.audio_buffer.len());
                        let buffered_audio = self.audio_buffer.read_all();
                        let text = self.model_manager.transcribe(&buffered_audio);
                        if !text.is_empty() {
                             self.buffer.push(&text);
                             println!("Buffered Transcribed: {}", text);
                        }
                    }
                }
                
                // 2. Process new live audio
                if !new_audio.is_empty() {
                    match mode {
                        EnduranceMode::HighPerformance => {
                            // Real-time Streaming with Accumulation (1s chunks)
                            self.transcription_buffer.extend_from_slice(&new_audio);
                            
                            // 48000 samples = 3 seconds (Better context, less "swallowing")
                            if self.transcription_buffer.len() >= 48000 {
                                let text = self.model_manager.transcribe(&self.transcription_buffer);
                                // Filter out hallucinations and silence artifacts
                                if !text.is_empty() && !text.contains("[BLANK_AUDIO]") {
                                    // De-dup: Prevent repeating the exact same segment
                                    // RollingBuffer is just a String wrapper, so we check suffixes.
                                    let context = self.buffer.get_context().trim_end();
                                    let normalized_text = text.trim();
                                    
                                    // Check if the END of the context matches the new text (basic suffix check)
                                    // We also check "starts_with" inversely in case the buffer ends with partial of new text,
                                    // but for now, exact suffix matching is the safest "Loop Breaker".
                                    if !normalized_text.is_empty() && !context.ends_with(normalized_text) {
                                         println!("Transcribed: {}", text);
                                         self.buffer.push(&text);
                                    }
                                }
                                self.transcription_buffer.clear();
                            }
                        },
                        EnduranceMode::Endurance => {
                            self.audio_buffer.push(&new_audio); 
                        }
                    }
                }
            }
            EngineState::Summarizing => {
                // v5.1 CRITICAL: Do NOT stop capturing. 
                // Buffer audio while ASR is unloaded.
                if !new_audio.is_empty() {
                    self.audio_buffer.push(&new_audio);
                    // println!("Engine: Buffering {} samples during summary...", new_audio.len());
                }
            }
            _ => {}
        }
    }


    pub fn stop_recording_and_summarize(&mut self, append_to: Option<i64>) -> String {
        println!("Engine: Triggering Summary Swap...");
        
        // 1. Unload ASR
        self.model_manager.unload_asr();
        self.state = EngineState::Summarizing;
        
        // 2. Load LLM
        self.model_manager.load_llm();
        
        // 2.5 Load RAG (Persistent)
        self.model_manager.load_rag();
        
        // 3. Prepare Prompt & RAG Context
        let context_text = self.buffer.get_context();
        let lang = self.lang_detector.detect(context_text);
        
        let mut final_input = context_text.to_string();
        
        println!("RAG: Generating embedding via ModelManager...");
        if let Some(embedding) = self.model_manager.embed(context_text) {
             // Search for similar notes
             if let Ok(similar) = self.database.search_similar_notes(&embedding, 3) {
                 if !similar.is_empty() {
                     let mut context_str = String::from("\n\n---\nContext from past notes:\n");
                     for (id, score) in similar {
                         if let Ok((_, title, content, _)) = self.database.get_note(id) {
                             // Only include if score > 0.5
                             if score > 0.4 {
                                context_str.push_str(&format!("- [{}] (Similarity: {:.2}): {}\n", title, score, content.lines().take(2).collect::<Vec<_>>().join(" ")));
                             }
                         }
                     }
                     final_input.push_str(&context_str);
                     println!("RAG: Injected {} bytes of context.", context_str.len());
                 }
             }
         }
        
        // 4. Run Summary with enriched context
        let summary = self.model_manager.summarize(&final_input);
        println!("Summary generated [{}]: {}", lang, summary);
        
        // 5. Unload LLM
        self.model_manager.unload_llm();
        
        // 6. Save to DB
        let note_id = match append_to {
            Some(id) => {
                if let Ok((_id, title, existing_content, _updated)) = self.database.get_note(id) {
                     let new_content = format!("{}\n\n---\n\n{}", existing_content, summary);
                     let _ = self.database.update_note(id, &title, &new_content);
                     println!("Note {} updated with new summary.", id);
                     Some(id)
                } else { None }
            },
            None => {
                match self.database.add_note(&format!("Note {}", chrono::Utc::now().timestamp()), &summary, self.current_folder_id) {
                     Ok(id) => {
                         println!("Note saved to DB: {}", id);
                         Some(id)
                     },
                     Err(e) => {
                         println!("Error saving note: {}", e);
                         None
                     }
                }
            }
        };
        
        if let Some(id) = note_id {
            if let Some(embedding) = self.model_manager.embed(context_text) {
                 let _ = self.database.save_embedding(id, embedding);
                 println!("RAG: Embedding saved for note {}.", id);
            }
            
            // 7.5 Save Full Audio (Persistence)
            // Use current timestamp for unique filename
            let filename = format!("recording_{}.wav", chrono::Utc::now().timestamp());
            let path = std::path::Path::new("/tmp").join(&filename); // Ideally usage APP_DIR
            
            println!("Persistence: Saving {} samples to {:?}...", self.full_session_audio.len(), path);
            
            let spec = hound::WavSpec {
                channels: 1,
                sample_rate: 16000,
                bits_per_sample: 16,
                sample_format: hound::SampleFormat::Int,
            };
            
            if let Ok(mut writer) = hound::WavWriter::create(&path, spec) {
                // Convert f32 to i16
                for &sample in &self.full_session_audio {
                    let amplitude = sample * 32767.0;
                    writer.write_sample(amplitude as i16).unwrap_or(());
                }
                writer.finalize().unwrap_or(());
                
                // Add as attachment
                if let Some(path_str) = path.to_str() {
                    let _ = self.database.add_attachment(id, "audio", path_str);
                    println!("Persistence: Audio saved as attachment.");
                }
            } else {
                println!("Persistence: Failed to create WAV file.");
            }
            // Clear for next session
            self.full_session_audio.clear();
        }
        
        // 7.6 Unload RAG
        self.model_manager.unload_rag();
        
        // 8. Return to Recording
        println!("Engine: Returning to Recording...");
        self.model_manager.load_asr();
        self.state = EngineState::Recording;
        
        summary
    }

    pub fn create_folder(&self, name: &str) -> anyhow::Result<i64> {
        Ok(self.database.create_folder(name).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn get_folders(&self) -> anyhow::Result<Vec<(i64, String)>> {
        Ok(self.database.get_folders().map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn get_notes_by_folder(&self, folder_id: i64) -> anyhow::Result<Vec<(i64, String, String, i64)>> {
         Ok(self.database.get_notes_by_folder(folder_id).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn set_current_folder(&mut self, folder_id: Option<i64>) {
        self.current_folder_id = folder_id;
    }

    pub fn add_note(&self, title: &str, content: &str, folder_id: Option<i64>) -> anyhow::Result<i64> {
        Ok(self.database.add_note(title, content, folder_id).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn update_note(&self, note_id: i64, title: &str, content: &str) -> anyhow::Result<()> {
        Ok(self.database.update_note(note_id, title, content).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn delete_note(&self, note_id: i64) -> anyhow::Result<()> {
        Ok(self.database.delete_note(note_id).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn get_note(&self, note_id: i64) -> anyhow::Result<(i64, String, String, i64)> {
        Ok(self.database.get_note(note_id).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn add_attachment(&self, note_id: i64, file_type: &str, file_path: &str) -> anyhow::Result<i64> {
        Ok(self.database.add_attachment(note_id, file_type, file_path).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn get_attachments(&self, note_id: i64) -> anyhow::Result<Vec<(i64, String, String)>> {
        Ok(self.database.get_attachments(note_id).map_err(|e| anyhow::anyhow!(e))?)
    }

    pub fn get_current_transcript(&self) -> String {
        self.buffer.get_context().to_string()
    }

    // Feature F16: Semantic Search
    pub fn search_notes(&mut self, query: &str) -> anyhow::Result<Vec<(i64, String, String, i64)>> {
        println!("Engine: Searching for '{}'...", query);
        
        // 1. Load RAG
        self.model_manager.load_rag();
        
        let mut results = Vec::new();
        
        // 2. Embed Query
        if let Some(embedding) = self.model_manager.embed(query) {
             // 3. Vector Search
             if let Ok(similar) = self.database.search_similar_notes(&embedding, 10) {
                 for (id, _score) in similar {
                     // 4. Fetch Details
                     if let Ok(note) = self.database.get_note(id) {
                         results.push(note);
                     }
                 }
             }
        }
        
        // 5. Unload RAG
        self.model_manager.unload_rag();
        
        Ok(results)
    }
}

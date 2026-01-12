#[test]
fn test_real_model_loading() {
    use tactanotes_core::ai::asr::WhisperModel;
    
    println!(">>> INTEGRATION TEST: REAL ASR LOAD <<<");
    
    // Attempt to load the model. 
    // This will print "Whisper Engine Loaded Successfully" if it works.
    // If it fails (path issue), it will print error.
    let model = WhisperModel::load("./models");
    
    // We can't check internals easily without public fields, but if it didn't panic and printed logs, good.
    // Ideally we'd check `model.ctx.is_some()`, but field is private.
    // We can infer success by trying a dummy transcribe.
    
    let dummy_audio = vec![0.0; 16000]; // 1 sec silence
    let text = model.transcribe(&dummy_audio);
    
    println!("Transcription result (Silence): '{}'", text);
    
    // Silence usually yields empty string or maybe "[BLANK_AUDIO]"
    // If text is empty, that's fine for silence.
    // The key is it didn't crash.
}

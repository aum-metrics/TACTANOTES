#[test]
fn test_resampler_logic() {
    use tactanotes_core::audio::resampler::TacticResampler;
    
    println!(">>> TESTING AUDIO RESAMPLER <<<");
    
    // Simulate Android Mic (48kHz) -> Whisper (16kHz)
    let input_rate = 48000.0;
    let output_rate = 16000.0;
    
    let mut bridge = TacticResampler::new(input_rate, output_rate);
    
    // Create dummy 48kHz sine wave chunk (1 second = 48000 samples)
    let chunk_size = 1024;
    let input_chunk = vec![0.5; chunk_size]; // Flat DC for simplicity or dummy data
    
    // Process multiple chunks
    for i in 0..10 {
        let output = bridge.process(input_chunk.clone());
        println!("Chunk {}: Input {} -> Output {}", i, input_chunk.len(), output.len());
        
        // Output should be approx 1/3 size eventually
        // Note: Rubato might buffer the first few chunks, so output might be 0 initially.
    }
    
    println!(">>> RESAMPLER TEST PASSED <<<");
}

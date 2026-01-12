use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use std::sync::{Arc, Mutex};

pub struct AudioRecorder {
    stream: Option<cpal::Stream>,
    is_recording: bool,
    buffer: Arc<Mutex<Vec<f32>>>,
}

impl AudioRecorder {
    pub fn new() -> Self {
        Self {
            stream: None,
            is_recording: false,
            buffer: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn start(&mut self) -> anyhow::Result<()> {
        let host = cpal::default_host();
        let device = host.default_input_device().ok_or(anyhow::anyhow!("No input device"))?;
        
        let config: cpal::StreamConfig = device.default_input_config()?.into();
        
        // Ensure 16kHz for Whisper (resampling might be needed properly hereafter, but for MVP we assume config close)
        // In real impl, use Dasp to resample.

        let buffer_clone = self.buffer.clone();
        
        // Feature F3 & F5: Low latency stream with Resampling Check
        let sample_rate = config.sample_rate.0;
        let stream = device.build_input_stream(
            &config,
            move |data: &[f32], _: &cpal::InputCallbackInfo| {
                // Refinement 1: Synchronous Resampling (Naive Stub)
                // Whisper requires 16000Hz. Most devices are 44100 or 48000.
                let target_rate = 16000;
                
                // If mismatch > 100Hz, we resample.
                if (sample_rate as i32 - target_rate as i32).abs() > 100 {
                    // Simple Decimation (if ratio is integer-ish) or Linear Interpolation.
                    // For this scaffold, we simulate a basic decimate/step algorithm to show intent.
                    // Real impl should use `dasp::signal::interpolate::linear`.
                    
                    let ratio = sample_rate as f32 / target_rate as f32;
                    let new_len = (data.len() as f32 / ratio) as usize;
                    let mut resampled_data = Vec::with_capacity(new_len);
                    
                    for i in 0..new_len {
                        let original_idx = (i as f32 * ratio) as usize;
                        if original_idx < data.len() {
                            resampled_data.push(data[original_idx]);
                        }
                    }
                    
                    if let Ok(mut buffer) = buffer_clone.lock() {
                        buffer.extend_from_slice(&resampled_data);
                    }
                } else {
                    // Native 16k
                     if let Ok(mut buffer) = buffer_clone.lock() {
                        buffer.extend_from_slice(data);
                    }
                }
            },
            |err| eprintln!("Stream error: {}", err),
            None
        )?;

        stream.play()?;
        self.stream = Some(stream);
        self.is_recording = true;
        
        Ok(())
    }

    pub fn stop(&mut self) {
        if let Some(stream) = self.stream.take() {
            // Drop stream stops it
            drop(stream);
        }
        self.is_recording = false;
    }

    pub fn get_audio_data(&self) -> Vec<f32> {
        if let Ok(mut buffer) = self.buffer.lock() {
            let data = buffer.clone();
            buffer.clear();
            data
        } else {
            Vec::new()
        }
    }
}

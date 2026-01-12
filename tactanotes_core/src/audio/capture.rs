use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use std::sync::{Arc, Mutex};

// Wrapper to allow Stream in Mutex (Unsafe but needed for global Engine)
struct SendStream(cpal::Stream);
unsafe impl Send for SendStream {}

pub struct AudioRecorder {
    stream: Option<SendStream>,
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
        
        // Feature F3 & Gap 4: High-Fidelity Sinc Resampling (Rubato)
        let sample_rate = config.sample_rate.0;
        let target_rate = 16000;
        
        let mut resampler_opt = if sample_rate != target_rate {
            Some(crate::audio::resampler::TacticResampler::new(
                sample_rate as f64,
                target_rate as f64
            ))
        } else {
            None
        };

        // Intermediate buffer to handle CPAL's variable chunk sizes
        let mut input_accumulator: Vec<f32> = Vec::with_capacity(2048);
        let _output_scratch: Vec<Vec<f32>> = vec![vec![0.0; 2048]; 1]; // pre-allocate

        let stream = device.build_input_stream(
            &config,
            move |data: &[f32], _: &cpal::InputCallbackInfo| {
                // Diagnostics: Calculate RMS to detect silence
                let mut sum_sq = 0.0;
                for &sample in data {
                    sum_sq += sample * sample;
                }
                let rms = (sum_sq / data.len() as f32).sqrt();

                if let Some(resampler) = &mut resampler_opt {
                     // 1. Accumulate input
                     input_accumulator.extend_from_slice(data);
                     
                     // 2. Process via TacticResampler
                     let chunk_size = resampler.input_frames_next();
                     while input_accumulator.len() >= chunk_size {
                         let chunk: Vec<f32> = input_accumulator.drain(0..chunk_size).collect();
                         
                         let channel_data = resampler.process(chunk);
                         if !channel_data.is_empty() {
                              if let Ok(mut buffer) = buffer_clone.lock() {
                                  buffer.extend_from_slice(&channel_data);
                                  // Log level occasionally
                                  if buffer.len() % 16000 < channel_data.len() {
                                      println!("AudioRecorder: [Resampled] Captured 1s (RMS: {:.4})", rms);
                                  }
                              }
                         }
                     }
                } else {
                    // Native 16k pass-through
                    if let Ok(mut buffer) = buffer_clone.lock() {
                        buffer.extend_from_slice(data);
                        if buffer.len() % 16000 < data.len() {
                            println!("AudioRecorder: [Native] Captured 1s (RMS: {:.4})", rms);
                        }
                    }
                }
            },
            |err| eprintln!("Stream error: {}", err),
            None
        )?;

        stream.play()?;
        self.stream = Some(SendStream(stream));
        self.is_recording = true;
        
        Ok(())
    }

    pub fn stop(&mut self) {
        if let Some(wrapper) = self.stream.take() {
            // Drop stream stops it
            drop(wrapper.0);
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

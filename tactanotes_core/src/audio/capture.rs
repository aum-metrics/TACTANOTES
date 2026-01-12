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
        
        // Feature F3 & Gap 4: High-Fidelity Sinc Resampling (Rubato)
        let sample_rate = config.sample_rate.0;
        let target_rate = 16000;
        
        let mut resampler_opt = if sample_rate != target_rate {
            use rubato::{Resampler, SincFixedIn, SincInterpolationType, SincInterpolationParameters, WindowFunction};
            let params = SincInterpolationParameters {
                sinc_len: 256,
                f_cutoff: 0.95,
                interpolation: SincInterpolationType::Linear,
                window: WindowFunction::BlackmanHarris2,
            };
            // 1024 input samples -> appropriate output samples
            Some(SincFixedIn::<f32>::new(
                target_rate as f64 / sample_rate as f64,
                2.0, // Max resample ratio
                params,
                1024, // Input chunk size
                1,    // Channels
            ).map_err(|e| anyhow::anyhow!("Resampler init failed: {}", e))?)
        } else {
            None
        };

        // Intermediate buffer to handle CPAL's variable chunk sizes
        let mut input_accumulator: Vec<f32> = Vec::with_capacity(2048);
        let mut output_scratch: Vec<Vec<f32>> = vec![vec![0.0; 2048]; 1]; // pre-allocate

        let stream = device.build_input_stream(
            &config,
            move |data: &[f32], _: &cpal::InputCallbackInfo| {
                if let Some(resampler) = &mut resampler_opt {
                     use rubato::Resampler;
                     // 1. Accumulate input
                     input_accumulator.extend_from_slice(data);
                     
                     // 2. Process in fixed chunks (Rubato requirement)
                     let chunk_size = resampler.input_frames_next();
                     while input_accumulator.len() >= chunk_size {
                         let chunk: Vec<f32> = input_accumulator.drain(0..chunk_size).collect();
                         let waves_in = vec![chunk];
                         
                         // 3. Sinc Interpolate
                         if let Ok(waves_out) = resampler.process(&waves_in, None) {
                             if let Some(channel_data) = waves_out.get(0) {
                                 if let Ok(mut buffer) = buffer_clone.lock() {
                                     buffer.extend_from_slice(channel_data);
                                 }
                             }
                         }
                         // Re-check next chunk size
                         // chunk_size = resampler.input_frames_next(); // For fixed_in it's constant usually
                     }
                } else {
                    // Native 16k pass-through
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

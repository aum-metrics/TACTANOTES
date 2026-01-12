use rubato::{Resampler, SincFixedIn, SincInterpolationType, SincInterpolationParameters, WindowFunction};

pub struct TacticResampler {
    resampler: SincFixedIn<f32>,
}

impl TacticResampler {
    pub fn new(input_hz: f64, output_hz: f64) -> Self {
        let params = SincInterpolationParameters {
            sinc_len: 256,
            f_cutoff: 0.95,
            interpolation: SincInterpolationType::Linear, // Balance speed/quality
            window: WindowFunction::BlackmanHarris2,
            oversampling_factor: 128,
        };
        // ratio = output / input (e.g., 16000 / 48000 = 0.333)
        // input chunk size 1024, 1 channel
        let resampler = SincFixedIn::<f32>::new(output_hz / input_hz, 2.0, params, 1024, 1).unwrap();
        Self { resampler }
    }

    pub fn process(&mut self, chunk: Vec<f32>) -> Vec<f32> {
        let input = vec![chunk];
        // .unwrap() is safe here because we guarantee chunk size upstream or handle error in real impl
        // For MVP speed, we assume valid input
        if let Ok(output) = self.resampler.process(&input, None) {
             if let Some(channel_data) = output.get(0) {
                 return channel_data.clone();
             }
        }
        Vec::new()
    }
    
    pub fn input_frames_next(&self) -> usize {
        self.resampler.input_frames_next()
    }
}

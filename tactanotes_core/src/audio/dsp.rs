pub struct HighPassFilter {
    alpha: f32,
    last_input: f32,
    last_output: f32,
}

impl HighPassFilter {
    pub fn new(sample_rate: f32, cutoff_freq: f32) -> Self {
        let rc = 1.0 / (2.0 * std::f32::consts::PI * cutoff_freq);
        let dt = 1.0 / sample_rate;
        let alpha = rc / (rc + dt);
        
        Self {
            alpha,
            last_input: 0.0,
            last_output: 0.0,
        }
    }
    
    pub fn process(&mut self, data: &mut [f32]) {
        for sample in data.iter_mut() {
            let input = *sample;
            // Simple 1st order HPF: y[i] := α * (y[i-1] + x[i] - x[i-1])
            let output = self.alpha * (self.last_output + input - self.last_input);
            
            self.last_input = input;
            self.last_output = output;
            *sample = output;
        }
    }
}

pub struct NoiseGate {
    threshold_linear: f32,
    attack: f32,
    release: f32,
    envelope: f32,
}

impl NoiseGate {
    pub fn new(threshold_db: f32) -> Self {
        Self {
            threshold_linear: 10.0f32.powf(threshold_db / 20.0),
            attack: 0.9,  // Fast attack
            release: 0.9995, // Slow release to avoid cutting tails
            envelope: 0.0,
        }
    }
    
    pub fn process(&mut self, data: &mut [f32]) {
        for sample in data.iter_mut() {
            let abs_input = sample.abs();
            
            // Envelope follower
            if abs_input > self.envelope {
                self.envelope = self.attack * self.envelope + (1.0 - self.attack) * abs_input;
            } else {
                self.envelope = self.release * self.envelope + (1.0 - self.release) * abs_input;
            }
            
            // Gate logic
            let gain = if self.envelope > self.threshold_linear {
                1.0 
            } else {
                // Smooth attenuation could go here, but hard gate for now to kill loop hallucinations
                0.0 
            };
            
            *sample *= gain;
        }
    }
}

use std::collections::VecDeque;

// Feature v5.1: 30-Second Circular Buffer for Lossless Swapping
// Capacity: 30s * 16kHz = 480,000 samples

pub struct CircularAudioBuffer {
    buffer: VecDeque<f32>,
    capacity: usize,
}

impl CircularAudioBuffer {
    pub fn new() -> Self {
        // 30 seconds at 16kHz
        let capacity = 30 * 16000;
        Self {
            buffer: VecDeque::with_capacity(capacity),
            capacity,
        }
    }

    pub fn push(&mut self, data: &[f32]) {
        for &sample in data {
            if self.buffer.len() == self.capacity {
                self.buffer.pop_front(); // Overwrite oldest if full (Safety valve)
            }
            self.buffer.push_back(sample);
        }
    }

    pub fn read_all(&mut self) -> Vec<f32> {
        self.buffer.drain(..).collect()
    }
    
    pub fn is_empty(&self) -> bool {
        self.buffer.is_empty()
    }
    
    pub fn len(&self) -> usize {
        self.buffer.len()
    }

    pub fn clear(&mut self) {
        self.buffer.clear();
    }
}

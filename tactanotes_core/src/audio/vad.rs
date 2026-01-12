pub struct VadEngine {
    // tract_onnx::SimplePlan lookup would go here
    _model_path: String
}

impl VadEngine {
    pub fn new(model_path: &str) -> Self {
        Self {
            _model_path: model_path.to_string()
        }
        // In real impl: Output would be loaded here.
    }

    pub fn is_speech(&mut self, _audio_chunk: &[f32]) -> bool {
        // Run ONNX inference
        // For scaffold: Return true
        true
    }
}

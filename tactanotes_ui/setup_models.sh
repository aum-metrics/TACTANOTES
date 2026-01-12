#!/bin/bash
# tactanotes_ui/setup_models.sh
set -e

echo "🧠 TACTANOTES v5.4 Model Setup"
echo "================================="

TARGET_DIR="assets/models"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "🧹 Cleaning old v5.3 models..."
rm -f distil-small.en-encoder.int8.onnx
rm -f decoder_model_quantized.onnx
rm -f encoder_model_quantized.onnx
rm -f model_q4f16.onnx_data
rm -f model_quantized.onnx
# Note: llm_model.onnx might be the new one or corrupt. We will overwrite if user asks, 
# but for safety let's leave valid files if they verify. 
# actually, easy path: Just download missing.

echo "⬇️  Downloading v5.4 Endurance Models..."

# 1. Silero VAD (Keep if exists)
if [ ! -f "silero_vad.onnx" ]; then
    echo "   Fetching VAD..."
    curl -L -o silero_vad.onnx https://github.com/snakers4/silero-vad/raw/master/files/silero_vad.onnx
fi

# 2. Whisper Tiny v3 (41MB) - Replaces Distil-Small
if [ ! -f "asr_model.onnx" ]; then
    echo "   Fetching Whisper-Tiny-v3..."
    curl -L -o asr_model.onnx https://huggingface.co/EmbeddedLLM/whisper-tiny-v3-onnx/resolve/main/model_quantized.onnx
fi

# 3. Qwen2.5-0.5B (340MB)
# If file exists but is small (<100MB), re-download.
if [ -f "llm_model.onnx" ]; then
    FSIZE=$(stat -f%z "llm_model.onnx" 2>/dev/null || stat -c%s "llm_model.onnx")
    if [ "$FSIZE" -lt 100000000 ]; then
        echo "   LLM file corrupt/small. Redownloading..."
        rm llm_model.onnx
    fi
fi

if [ ! -f "llm_model.onnx" ]; then
    echo "   Fetching Qwen2.5-0.5B..."
    curl -L -o llm_model.onnx https://huggingface.co/EmbeddedLLM/Qwen2.5-0.5B-Instruct-ONNX/resolve/main/model_quantized.onnx
fi

# 4. Vector Engine (MiniLM)
if [ ! -f "vector_model.onnx" ]; then
    echo "   Fetching MiniLM Vector..."
    curl -L -o vector_model.onnx https://huggingface.co/EmbeddedLLM/all-MiniLM-L6-v2-onnx/resolve/main/model_quantized.onnx
fi

echo "✅ Model Setup Complete!"
ls -lh

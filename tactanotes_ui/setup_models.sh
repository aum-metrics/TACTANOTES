#!/bin/bash
# tactanotes_ui/setup_models.sh
set -e

# Ensure we are in the script's directory's parent (tactanotes_ui) to find assets correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/assets/models"

echo "🧠 TACTANOTES v5.4 Model Setup (Corrected)"
echo "==========================================="
echo "Target Dir: $TARGET_DIR"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Cleanup Helper: Remove small/corrupt files (<1KB)
find . -name "*.onnx" -size -1k -delete

echo "🧹 Cleaning legacy v5.3 models..."
rm -f distil-small.en-encoder.int8.onnx
rm -f decoder_model_quantized.onnx
rm -f encoder_model_quantized.onnx
rm -f model_q4f16.onnx_data
rm -f model_quantized.onnx

echo "⬇️  Downloading v5.4 Endurance Models (Xenova/ONNX)..."

# 1. Silero VAD (Keep if valid)
if [ ! -f "silero_vad.onnx" ]; then
    echo "   Fetching VAD..."
    curl -L -o silero_vad.onnx https://github.com/snakers4/silero-vad/raw/master/files/silero_vad.onnx
fi

# 2. Whisper Tiny v3 (Xenova) - Encoder Only (Sufficient for V5.4 Mock Architecture)
# URL: https://huggingface.co/Xenova/whisper-tiny/resolve/main/onnx/encoder_model_quantized.onnx
if [ ! -f "asr_model.onnx" ]; then
    echo "   Fetching Whisper-Tiny (Int8)..."
    curl -L -o asr_model.onnx "https://huggingface.co/Xenova/whisper-tiny/resolve/main/onnx/encoder_model_quantized.onnx"
fi

# 3. Qwen 2.5 0.5B (Xenova)
# URL: https://huggingface.co/Xenova/Qwen2.5-0.5B-Instruct/resolve/main/onnx/model_quantized.onnx
if [ ! -f "llm_model.onnx" ]; then
    echo "   Fetching Qwen2.5-0.5B (Int8)..."
    curl -L -o llm_model.onnx "https://huggingface.co/Xenova/Qwen2.5-0.5B-Instruct/resolve/main/onnx/model_quantized.onnx"
fi

# 4. Vector Engine (MiniLM)
# URL: https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model_quantized.onnx
if [ ! -f "vector_model.onnx" ]; then
    echo "   Fetching MiniLM Vector..."
    curl -L -o vector_model.onnx "https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model_quantized.onnx"
fi

echo "✅ Model Setup Complete!"
ls -lh

# 🧠 TACTANOTES v5.4 (Endurance Build)

**The AI-First, Offline-First Note Taking Engine.**
*Privacy by Physics. Intelligence by Design.*

## 🚀 Overview
TACTANOTES is a high-performance voice note-taking application designed for total privacy on **Global South Hardware (3GB-4GB RAM)**. It runs on-device AI inference (ASR, LLM, RAG) using a **Rust Kernel** wrapped in a **Flutter UI**.

*   **Offline-First**: Zero data leaves the device without explicit "Cloud Sync".
*   **Endurance-Tuned**: Optimized for 10-hour battery life and <500MB Peak RAM.
*   **Data Safety Statement**: TACTANOTES performs speech recognition and summarization entirely on-device. Audio, transcripts, and summaries are never transmitted off-device unless the user explicitly enables encrypted cloud backup.

---

## 🛠️ Architecture Stack (Endurance Edition)

| Component | Technology | Spec | Peak RAM (Est) |
| :--- | :--- | :--- | :--- |
| **Logic Core** | Rust (via FRB) | Threading, Thermal Management. | ~10 MB |
| **Audio Engine** | `rubato` + `cpal` | **Sinc Resampling** (No-Metallic Bridge). | ~5 MB |
| **ASR** | Whisper-Tiny-v3 | Real-time Speech-to-Text (Int8). | **~70 MB** |
| **Summarizer** | Qwen2.5-0.5B | Offline Instruct LLM (IQ4_XS). | **~375 MB** |
| **Vector Engine** | MiniLM-L6-v2 | RAG / Semantic Search (Int8). | **~45 MB** |
| **VAD** | Silero v5 | Voice Activity Detection. | < 10 MB |

### 🧠 Memory Budget (The 512MB Rule)
We strictly adhere to a **500MB Peak Footprint** to leave a 400MB safety margin before the Android LMK (Low Memory Killer) intervenes.

*   **Strategy**: `mlock` is explicitly **DISABLED** to allow OS paging compliance.
*   **Thermal**: If Temp > 42°C (Battery Fallback), LLM inference halts.

---

## ⚡️ Quick Start (The "Fix It" Script)

This project uses a hybrid build system. Use the included auto-repair script to initialize the bridge and platform folders.

### 1. Prerequisites
*   **Flutter SDK** (3.x+)
*   **Rust Toolchain** (`cargo` with Android NDK targets)
*   **Android Studio** (or Xcode for iOS)

### 2. Initialization
Run this **single command** to generate the Android/iOS folders and the Rust FFI bindings:

```bash
./fix_project.sh
```

### 3. AI Model Setup (v5.4 Endurance Pack)
The AI models are too large for Git. You must download the **Endurance-Optimized** versions manually:

```bash
cd tactanotes_ui/assets/models/

# 1. Silero VAD v5 (2MB)
curl -L -o vad_model.onnx https://github.com/snakers4/silero-vad/raw/master/files/silero_vad.onnx

# 2. Qwen2.5-0.5B-Instruct (340MB - IQ4_XS) - The "Endurance" Model
curl -L -o llm_model.onnx https://huggingface.co/EmbeddedLLM/Qwen2.5-0.5B-Instruct-ONNX/resolve/main/model_quantized.onnx

# 3. Whisper-Tiny-v3 (41MB - Int8)
curl -L -o asr_model.onnx https://huggingface.co/EmbeddedLLM/whisper-tiny-v3-onnx/resolve/main/model_quantized.onnx

# 4. Vector Engine (MiniLM - 23MB)
curl -L -o vector_model.onnx https://huggingface.co/EmbeddedLLM/all-MiniLM-L6-v2-onnx/resolve/main/model_quantized.onnx
```

### 4. Run It
```bash
cd tactanotes_ui
flutter run
```

---

## 🛡️ Key Features (v5.3)

### 🌡️ Hybrid Thermal Vitals
To prevent overheating during long sessions, the **Endurance Engine** monitors both:
1.  **CPU Temp**: Via `/sys/class/thermal` (Primary).
2.  **Battery Temp**: Via Android API (Fallback).
*If heat > 42°C, the app enters "Endurance Mode" (Batch AI).*

### ☁️ Cloud Delta Sync
*   **Encrypted Sync**: Data is packed into `SyncBlob` format (AES-256) before upload.
*   **Mock Registry**: Hybrid Registration collects only anonymous installation metrics (OS version, device class). No audio, text, or behavioral data is collected.

### 🎧 Rubato Audio
Uses **Sinc Interpolation** instead of basic decimation to prevent "metallic" voice artifacts when downsampling from 48kHz to 16kHz.

---

## 📜 License
Private & Confidential.
Built for the **Advanced Agentic Coding** initiative.

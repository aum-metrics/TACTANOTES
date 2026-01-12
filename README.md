# 🧠 TACTANOTES v5.3 (Deployment Build)

**The AI-First, Offline-First Note Taking Engine.**
*Privacy by Physics. Intelligence by Design.*

## 🚀 Overview
TACTANOTES is a high-performance voice note-taking application designed for total privacy. It runs on-device AI inference (ASR, LLM, RAG) using a **Rust Kernel** wrapped in a **Flutter UI**.

*   **Offline-First**: Zero data leaves the device without explicit "Cloud Sync".
*   **Hybrid Architecture**: Flutter handles the UI/UX, while Rust manages Audio (Rubato), AI (ONNX), and Encryption (Argon2/AES).
*   **Privacy**: Adheres to Google Play 2026 data safety standards.

---

## 🛠️ Architecture Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **UI Shell** | Flutter (Dart) | Fluid Animations, Stealth Mode, OLED Optimization. |
| **Logic Core** | Rust (via FRB) | Application state, Threading, Thermal Management. |
| **Audio Engine** | `rubato` + `cpal` | Hi-Fi Sinc Resampling (48kHz -> 16kHz) & VAD. |
| **ASR** | Distil-Small (Int8) | Real-time Speech-to-Text (102MB). |
| **Intelligence** | Gemma-2 (2B-Int4) | Offline Summarization (425MB) via mmap. |
| **Database** | SQLite + FTS5 | Encrypted storage & "Zen Search". |

### 🧠 Memory Budget (The 512MB Challenge)
To run large models on low-end devices, we use **Interleaved Inference**:

| State | Models Loaded | RAM Usage | Purpose |
| :--- | :--- | :--- | :--- |
| **State A (Record)** | ASR + VAD | **~150 MB** | Real-time transcription. |
| **State B (Think)** | LLM + Vector | **~460 MB** | Summarization & Organization. |
*The system aggressively unloads ASR before loading the LLM.*

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

### 3. AI Model Setup (Critical!)
The AI models are too large for Git (>500MB). You must download them manually into `tactanotes_ui/assets/models/`:

```bash
cd tactanotes_ui/assets/models/

# 1. Silero VAD (2MB)
curl -L -o vad_model.onnx https://github.com/snakers4/silero-vad/raw/master/files/silero_vad.onnx

# 2. Gemma 2 (2B) Mobile Optimized (~1.5GB)
curl -L -o llm_model.onnx https://huggingface.co/EmbeddedLLM/gemma-2b-it-onnx/resolve/main/model_quantized.onnx

# 3. Whisper Distil-Small (102MB)
curl -L -o distil-small.en-encoder.int8.onnx https://huggingface.co/EmbeddedLLM/distil-small.en-onnx/resolve/main/encoder_model_quantized.onnx
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
*   **Mock Registry**: Features a "Hybrid Registration" flow for user metrics without compromising data privacy.

### 🎧 Rubato Audio
Uses **Sinc Interpolation** instead of basic decimation to prevent "metallic" voice artifacts when downsampling from 48kHz to 16kHz.

---

## 📜 License
Private & Confidential.
Built for the **Advanced Agentic Coding** initiative.

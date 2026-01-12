mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod api;
pub mod audio;
pub mod storage;
pub mod ai;
pub mod engine;
pub mod ocr;

#[cfg(not(target_arch = "wasm32"))]
use mimalloc::MiMalloc;

#[cfg(not(target_arch = "wasm32"))]
#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

pub use audio::capture::AudioRecorder;
pub use storage::db::Database;
pub use engine::Engine;
pub use ocr::OcrEngine;

pub mod api;
pub mod audio;
pub mod storage;
pub mod ai;
pub mod engine;
pub mod ocr;

use mimalloc::MiMalloc;

#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

pub use audio::capture::AudioRecorder;
pub use storage::db::Database;
pub use engine::Engine;
pub use ocr::OcrEngine;

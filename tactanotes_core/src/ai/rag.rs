use fastembed::{TextEmbedding, InitOptions, EmbeddingModel};
use std::sync::Arc;

pub struct VectorStore {
    model: Arc<TextEmbedding>,
}

impl VectorStore {
    pub fn new() -> anyhow::Result<Self> {
        println!("Loading Embedding Model (MiniLM-L6-v2)...");
        let model = TextEmbedding::try_new(InitOptions::new(EmbeddingModel::AllMiniLML6V2).with_show_download_progress(true))?;
        
        Ok(Self {
            model: Arc::new(model),
        })
    }

    pub fn embed(&self, text: &str) -> anyhow::Result<Vec<f32>> {
        let documents = vec![text.to_string()];
        let embeddings = self.model.embed(documents, None)?;
        
        // Return the first embedding (since we only requested one document)
        if let Some(embedding) = embeddings.first() {
            Ok(embedding.clone())
        } else {
            Err(anyhow::anyhow!("Failed to generate embedding"))
        }
    }
}

use ring::aead::{self, LessSafeKey, UnboundKey, NONCE_LEN};
use ring::rand::{SecureRandom, SystemRandom};
use anyhow::Result;

// Feature F14: Encryption at Rest (AES-256-GCM)

pub struct Encryptor {
    key: LessSafeKey,
    rng: SystemRandom,
}

impl Encryptor {
    pub fn new(password: &str) -> Self {
        // In production: Use Argon2 to derive key from password + salt
        // Here: Simplified for scaffold (Hash password to 32 bytes)
        // WARN: Do not use simple sha256 for key derivation in prod without salt.
        let mut key_bytes = [0u8; 32];
        let bytes = password.as_bytes();
        for (i, b) in bytes.iter().enumerate() {
            key_bytes[i % 32] ^= b;
        }

        let unbound_key = UnboundKey::new(&aead::AES_256_GCM, &key_bytes).unwrap();
        Self {
            key: LessSafeKey::new(unbound_key),
            rng: SystemRandom::new(),
        }
    }

    pub fn encrypt(&self, data: &[u8]) -> Result<Vec<u8>> {
        let mut nonce_bytes = [0u8; NONCE_LEN];
        self.rng.fill(&mut nonce_bytes).map_err(|_| anyhow::anyhow!("RNG failed"))?;
        let nonce = aead::Nonce::try_assume_unique_for_key(&nonce_bytes).unwrap();

        // Data layout: [Nonce (12 bytes)] + [Ciphertext] + [Tag (included in ciphertext by ring)]
        let mut in_out = data.to_vec();
        
        // Ring encrypts in-place and appends tag
        self.key.seal_in_place_append_tag(nonce, aead::Aad::empty(), &mut in_out)
            .map_err(|_| anyhow::anyhow!("Encryption failed"))?;
            
        // Prepend nonce
        let mut result = nonce_bytes.to_vec();
        result.append(&mut in_out);
        
        Ok(result)
    }

    pub fn decrypt(&self, data: &[u8]) -> Result<Vec<u8>> {
        if data.len() < NONCE_LEN {
            return Err(anyhow::anyhow!("Data too short"));
        }

        let nonce_bytes = &data[..NONCE_LEN];
        let mut in_out = data[NONCE_LEN..].to_vec();
        
        let nonce = aead::Nonce::try_assume_unique_for_key(nonce_bytes).unwrap();
        
        let decrypted_data = self.key.open_in_place(nonce, aead::Aad::empty(), &mut in_out)
            .map_err(|_| anyhow::anyhow!("Decryption failed"))?;
            
        Ok(decrypted_data.to_vec())
    }
}

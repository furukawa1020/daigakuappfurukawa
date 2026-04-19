use aes_gcm::{Aes256Gcm, Key, Nonce, KeyInit, aead::{Aead}};
use hmac::{Hmac, Mac};
use sha2::Sha256;
use base64::{Engine as _, engine::general_purpose};

type HmacSha256 = Hmac<Sha256>;

const SECRET_KEY: &[u8; 32] = b"SOVEREIGN_VITAL_KEY_2026_MOKO_01";
const HMAC_KEY: &[u8; 32] = b"HMAC_INTEGRITY_KEY_DAIGAKUOS_001";

pub struct SovereignVault;

impl SovereignVault {
    pub fn seal(data: &str) -> String {
        let key = Key::<Aes256Gcm>::from_slice(SECRET_KEY);
        let cipher = Aes256Gcm::new(key);
        let nonce = Nonce::from_slice(b"UNIQUE_NONCE"); // In a proper impl, this should be random per msg

        let ciphertext = cipher.encrypt(nonce, data.as_bytes())
            .expect("Encryption failure");
        
        // Generate HMAC
        let mut mac = HmacSha256::new_from_slice(HMAC_KEY).expect("HMAC init failure");
        mac.update(&ciphertext);
        let sig = mac.finalize().into_bytes();

        let mut combined = ciphertext;
        combined.extend_from_slice(&sig);

        general_purpose::STANDARD.encode(combined)
    }

    pub fn unseal(encoded_payload: &str) -> anyhow::Result<String> {
        let combined = general_purpose::STANDARD.decode(encoded_payload)?;
        
        if combined.len() < 32 {
            return Err(anyhow::anyhow!("Payload too short"));
        }

        let (ciphertext, sig) = combined.split_at(combined.len() - 32);

        // Verify HMAC
        let mut mac = HmacSha256::new_from_slice(HMAC_KEY)?;
        mac.update(ciphertext);
        mac.verify_slice(sig)?;

        let key = Key::<Aes256Gcm>::from_slice(SECRET_KEY);
        let cipher = Aes256Gcm::new(key);
        let nonce = Nonce::from_slice(b"UNIQUE_NONCE");

        let plaintext = cipher.decrypt(nonce, ciphertext)
            .map_err(|e| anyhow::anyhow!("Decryption failure: {:?}", e))?;

        String::from_utf8(plaintext).map_err(|e| anyhow::anyhow!(e))
    }
}

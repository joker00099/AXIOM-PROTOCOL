use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use crate::types::{Address, TxHash};

/// Axiom transaction
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub from: Address,
    pub to: Address,
    pub amount: u64,
    pub fee: u64,
    pub nonce: u64,
    pub timestamp: u64,
    pub signature: Vec<u8>,
}

impl Transaction {
    /// Get transaction hash
    pub fn hash(&self) -> TxHash {
        let mut hasher = Sha256::new();
        hasher.update(&self.from.0);
        hasher.update(&self.to.0);
        hasher.update(&self.amount.to_le_bytes());
        hasher.update(&self.fee.to_le_bytes());
        hasher.update(&self.nonce.to_le_bytes());
        hasher.update(&self.timestamp.to_le_bytes());
        
        let hash = hasher.finalize();
        let mut hash_bytes = [0u8; 32];
        hash_bytes.copy_from_slice(&hash);
        
        TxHash(hash_bytes)
    }
    
    /// Get message to sign
    pub(crate) fn signing_message(&self) -> Vec<u8> {
        let mut message = Vec::new();
        message.extend_from_slice(&self.from.0);
        message.extend_from_slice(&self.to.0);
        message.extend_from_slice(&self.amount.to_le_bytes());
        message.extend_from_slice(&self.fee.to_le_bytes());
        message.extend_from_slice(&self.nonce.to_le_bytes());
        message.extend_from_slice(&self.timestamp.to_le_bytes());
        message
    }
    
    /// Serialize transaction for network transmission
    pub fn to_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(self).unwrap()
    }
    
    /// Deserialize transaction from bytes
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, serde_json::Error> {
        serde_json::from_slice(bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_transaction_hash() {
        let tx = Transaction {
            from: Address([1u8; 32]),
            to: Address([2u8; 32]),
            amount: 1000,
            fee: 100,
            nonce: 0,
            timestamp: 1234567890,
            signature: vec![],
        };
        
        let hash = tx.hash();
        assert_eq!(hash.0.len(), 32);
    }
    
    #[test]
    fn test_transaction_serialization() {
        let tx = Transaction {
            from: Address([1u8; 32]),
            to: Address([2u8; 32]),
            amount: 1000,
            fee: 100,
            nonce: 0,
            timestamp: 1234567890,
            signature: vec![1, 2, 3],
        };
        
        let bytes = tx.to_bytes();
        let decoded = Transaction::from_bytes(&bytes).unwrap();
        
        assert_eq!(tx.amount, decoded.amount);
        assert_eq!(tx.signature, decoded.signature);
    }
}

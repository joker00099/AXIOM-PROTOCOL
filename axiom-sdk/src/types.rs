use serde::{Deserialize, Serialize};

/// Axiom address (32 bytes)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Address(pub [u8; 32]);

impl Address {
    pub fn from_bytes(bytes: [u8; 32]) -> Self {
        Self(bytes)
    }
    
    pub fn to_hex(&self) -> String {
        format!("axm1{}", hex::encode(&self.0))
    }
    
    pub fn from_hex(s: &str) -> Result<Self, String> {
        let s = s.strip_prefix("axm1").unwrap_or(s);
        let bytes = hex::decode(s).map_err(|e| e.to_string())?;
        if bytes.len() != 32 {
            return Err(format!("Invalid address length: {}", bytes.len()));
        }
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&bytes);
        Ok(Self(arr))
    }
    
    pub fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl std::fmt::Display for Address {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

/// Balance in satoshis (1 AXM = 100,000,000 satoshis)
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct Balance(pub u64);

impl Balance {
    pub const SATOSHIS_PER_AXM: u64 = 100_000_000;
    
    pub fn from_axm(axm: f64) -> Self {
        Self((axm * Self::SATOSHIS_PER_AXM as f64) as u64)
    }
    
    pub fn from_satoshis(satoshis: u64) -> Self {
        Self(satoshis)
    }
    
    pub fn as_axm(&self) -> f64 {
        self.0 as f64 / Self::SATOSHIS_PER_AXM as f64
    }
    
    pub fn as_satoshis(&self) -> u64 {
        self.0
    }
}

impl std::fmt::Display for Balance {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:.8} AXM", self.as_axm())
    }
}

/// Transaction hash
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct TxHash(pub [u8; 32]);

impl TxHash {
    pub fn from_bytes(bytes: [u8; 32]) -> Self {
        Self(bytes)
    }
    
    pub fn to_hex(&self) -> String {
        hex::encode(&self.0)
    }
    
    pub fn from_hex(s: &str) -> Result<Self, String> {
        let bytes = hex::decode(s).map_err(|e| e.to_string())?;
        if bytes.len() != 32 {
            return Err(format!("Invalid hash length: {}", bytes.len()));
        }
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&bytes);
        Ok(Self(arr))
    }
}

impl std::fmt::Display for TxHash {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_hex())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_address_hex() {
        let addr = Address([1u8; 32]);
        let hex = addr.to_hex();
        assert!(hex.starts_with("axm1"));
        
        let decoded = Address::from_hex(&hex).unwrap();
        assert_eq!(addr, decoded);
    }
    
    #[test]
    fn test_balance_conversion() {
        let balance = Balance::from_axm(1.5);
        assert_eq!(balance.as_satoshis(), 150_000_000);
        assert_eq!(balance.as_axm(), 1.5);
    }
    
    #[test]
    fn test_tx_hash_hex() {
        let hash = TxHash([255u8; 32]);
        let hex = hash.to_hex();
        let decoded = TxHash::from_hex(&hex).unwrap();
        assert_eq!(hash, decoded);
    }
}

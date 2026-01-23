use reqwest::Client;
use serde::{Deserialize, Serialize};
use crate::types::{Address, Balance, TxHash};
use crate::transaction::Transaction;
use crate::error::{AxiomError, Result};

/// RPC client for Axiom network
pub struct AxiomClient {
    rpc_url: String,
    client: Client,
}

impl AxiomClient {
    /// Create new RPC client
    pub async fn new(rpc_url: &str) -> Result<Self> {
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(30))
            .build()?;
        
        Ok(Self {
            rpc_url: rpc_url.to_string(),
            client,
        })
    }
    
    /// Get balance for an address
    pub async fn get_balance(&self, address: &Address) -> Result<Balance> {
        #[derive(Serialize)]
        struct BalanceRequest {
            address: String,
        }
        
        #[derive(Deserialize)]
        struct BalanceResponse {
            balance: u64,
        }
        
        let req = BalanceRequest {
            address: address.to_hex(),
        };
        
        let resp = self.client
            .post(format!("{}/balance", self.rpc_url))
            .json(&req)
            .send()
            .await?;
        
        if !resp.status().is_success() {
            return Err(AxiomError::Network(format!("HTTP {}", resp.status())));
        }
        
        let balance_resp: BalanceResponse = resp.json().await?;
        Ok(Balance(balance_resp.balance))
    }
    
    /// Get current nonce for an address
    pub async fn get_nonce(&self, address: &Address) -> Result<u64> {
        #[derive(Serialize)]
        struct NonceRequest {
            address: String,
        }
        
        #[derive(Deserialize)]
        struct NonceResponse {
            nonce: u64,
        }
        
        let req = NonceRequest {
            address: address.to_hex(),
        };
        
        let resp = self.client
            .post(format!("{}/nonce", self.rpc_url))
            .json(&req)
            .send()
            .await?;
        
        if !resp.status().is_success() {
            return Err(AxiomError::Network(format!("HTTP {}", resp.status())));
        }
        
        let nonce_resp: NonceResponse = resp.json().await?;
        Ok(nonce_resp.nonce)
    }
    
    /// Broadcast a transaction to the network
    pub async fn broadcast_transaction(&self, tx: Transaction) -> Result<TxHash> {
        #[derive(Deserialize)]
        struct TxResponse {
            hash: String,
        }
        
        let resp = self.client
            .post(format!("{}/broadcast", self.rpc_url))
            .json(&tx)
            .send()
            .await?;
        
        if !resp.status().is_success() {
            let error_text = resp.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            return Err(AxiomError::TransactionFailed(error_text));
        }
        
        let tx_resp: TxResponse = resp.json().await?;
        TxHash::from_hex(&tx_resp.hash)
            .map_err(|e| AxiomError::InvalidResponse(e))
    }
    
    /// Get transaction by hash
    pub async fn get_transaction(&self, hash: &TxHash) -> Result<Option<Transaction>> {
        #[derive(Serialize)]
        struct TxRequest {
            hash: String,
        }
        
        let req = TxRequest {
            hash: hash.to_hex(),
        };
        
        let resp = self.client
            .post(format!("{}/transaction", self.rpc_url))
            .json(&req)
            .send()
            .await?;
        
        if resp.status() == 404 {
            return Ok(None);
        }
        
        if !resp.status().is_success() {
            return Err(AxiomError::Network(format!("HTTP {}", resp.status())));
        }
        
        let tx: Transaction = resp.json().await?;
        Ok(Some(tx))
    }
    
    /// Get current block height
    pub async fn get_block_height(&self) -> Result<u64> {
        #[derive(Deserialize)]
        struct HeightResponse {
            height: u64,
        }
        
        let resp = self.client
            .get(format!("{}/height", self.rpc_url))
            .send()
            .await?;
        
        if !resp.status().is_success() {
            return Err(AxiomError::Network(format!("HTTP {}", resp.status())));
        }
        
        let height_resp: HeightResponse = resp.json().await?;
        Ok(height_resp.height)
    }
    
    /// Check if node is healthy
    pub async fn health_check(&self) -> Result<bool> {
        let resp = self.client
            .get(format!("{}/health", self.rpc_url))
            .send()
            .await?;
        
        Ok(resp.status().is_success())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_client_creation() {
        let client = AxiomClient::new("http://localhost:8545").await;
        assert!(client.is_ok());
    }
}

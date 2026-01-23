# Axiom SDK

Official Rust SDK for **Axiom Protocol** - Privacy-First Blockchain with VDF + PoW Consensus

[![Crates.io](https://img.shields.io/crates/v/axiom-sdk.svg)](https://crates.io/crates/axiom-sdk)
[![Documentation](https://docs.rs/axiom-sdk/badge.svg)](https://docs.rs/axiom-sdk)
[![License](https://img.shields.io/crates/l/axiom-sdk.svg)](https://github.com/Ghost-84M/Axiom-Protocol/blob/main/LICENSE)

## Features

- ✅ **Wallet Management** - Create, import, and export wallets
- ✅ **Transaction Signing** - Ed25519 signature support
- ✅ **RPC Client** - Connect to Axiom nodes
- ✅ **Type-Safe API** - Rust's type system ensures correctness
- ✅ **Async/Await** - Built on Tokio for high performance
- ✅ **View Keys** - Optional privacy controls for compliance
- ✅ **Cross-Chain Bridge** - Interact with bridge contracts

## Quick Start

Add to your `Cargo.toml`:

```toml
[dependencies]
axiom-sdk = "1.0"
tokio = { version = "1", features = ["full"] }
```

### Basic Example

```rust
use axiom_sdk::{AxiomClient, Wallet, NetworkConfig};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Connect to mainnet
    let config = NetworkConfig::mainnet();
    let client = AxiomClient::new(&config.rpc_url).await?;
    
    // Create a new wallet
    let wallet = Wallet::new();
    println!("Your address: {}", wallet.address_hex());
    
    // Check balance
    let balance = client.get_balance(&wallet.address()).await?;
    println!("Balance: {}", balance);
    
    // Send transaction
    let tx = wallet.create_transaction(
        "axm1recipient_address_here",
        1_000_000_000,  // 1 AXM
        100_000_000,    // 0.1 AXM fee
    )?;
    
    let tx_hash = client.broadcast_transaction(tx).await?;
    println!("Transaction sent: {}", tx_hash);
    
    Ok(())
}
```

### Wallet Management

```rust
use axiom_sdk::Wallet;

// Create new wallet
let wallet = Wallet::new();

// Export secret key (keep safe!)
let secret = wallet.export_secret_key();
println!("Secret: {}", hex::encode(secret));

// Import wallet from secret key
let imported = Wallet::from_secret_key(secret)?;
assert_eq!(wallet.address(), imported.address());
```

### Balance Checking

```rust
use axiom_sdk::{AxiomClient, Balance};

let client = AxiomClient::new("https://rpc.axiom.network").await?;

// Get balance
let balance = client.get_balance(&wallet.address()).await?;

// Convert to AXM
println!("Balance: {} AXM", balance.as_axm());
println!("Balance: {} satoshis", balance.as_satoshis());

// Create balance from AXM
let one_axm = Balance::from_axm(1.0);
println!("1 AXM = {} satoshis", one_axm.as_satoshis());
```

### Transaction Creation

```rust
// Get current nonce
let nonce = client.get_nonce(&wallet.address()).await?;

// Create transaction with nonce
let mut tx = wallet.create_transaction(
    "axm1...",
    1_000_000,  // Amount in satoshis
    10_000,     // Fee in satoshis
)?;
tx.nonce = nonce;

// Broadcast
let hash = client.broadcast_transaction(tx).await?;
println!("TX: {}", hash);
```

### Network Configuration

```rust
use axiom_sdk::NetworkConfig;

// Mainnet
let mainnet = NetworkConfig::mainnet();
// Chain ID: 84000
// RPC: https://rpc.axiom.network

// Testnet
let testnet = NetworkConfig::testnet();
// Chain ID: 84001
// RPC: https://testnet-rpc.axiom.network

// Custom network
let custom = NetworkConfig::custom(
    12345,
    "http://localhost:8545".to_string(),
    "http://localhost:8080".to_string(),
);
```

## Examples

See the `examples/` directory for more:

- [`quick_start.rs`](examples/quick_start.rs) - Basic wallet and transaction
- [`view_keys.rs`](examples/view_keys.rs) - Privacy controls for compliance

Run examples:

```bash
cargo run --example quick_start
cargo run --example view_keys
```

## API Reference

### Core Types

- **`Wallet`** - Ed25519 keypair for signing transactions
- **`Address`** - 32-byte blockchain address (axm1...)
- **`Balance`** - Amount in satoshis (1 AXM = 100,000,000 satoshis)
- **`Transaction`** - Signed transaction ready for broadcast
- **`TxHash`** - 32-byte transaction hash
- **`AxiomClient`** - RPC client for node communication

### Client Methods

```rust
// Balance and nonce
pub async fn get_balance(&self, address: &Address) -> Result<Balance>
pub async fn get_nonce(&self, address: &Address) -> Result<u64>

// Transactions
pub async fn broadcast_transaction(&self, tx: Transaction) -> Result<TxHash>
pub async fn get_transaction(&self, hash: &TxHash) -> Result<Option<Transaction>>

// Network info
pub async fn get_block_height(&self) -> Result<u64>
pub async fn health_check(&self) -> Result<bool>
```

## Testing

```bash
# Run all tests
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test test_wallet_creation
```

## Documentation

Build documentation:

```bash
cargo doc --open
```

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../CONTRIBUTING.md)

## License

Licensed under either of:

- Apache License, Version 2.0 ([LICENSE-APACHE](../LICENSE-APACHE))
- MIT License ([LICENSE-MIT](../LICENSE-MIT))

at your option.

## Links

- **Website**: https://axiom.network
- **GitHub**: https://github.com/Ghost-84M/Axiom-Protocol
- **Explorer**: https://explorer.axiom.network
- **Documentation**: https://docs.axiom.network

## Support

- Discord: https://discord.gg/axiom
- Telegram: https://t.me/axiomprotocol
- Email: dev@axiom.network

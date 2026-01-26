AXIOM Protocol — Academic Summary

Abstract

AXIOM is a privacy-preserving blockchain protocol that prioritizes verifiable mathematical properties over financial narratives. The protocol combines a Verifiable Delay Function (Wesolowski VDF) with Proof-of-Work to yield time-based fairness, and Groth16 ZK-SNARKs on BLS12-381 to enable private transaction validation.

Design Principles

- Mathematical scarcity: supply defined and provable by protocol rules.
- Provable supply cap: the monetary policy is encoded in consensus and deterministically enforced.
- Verifiable economics: all issuance and fee mechanisms are transparent and auditable by protocol observers.
- Fixed-supply protocol: supply schedule is deterministic and immutable in the genesis state.

Technical Highlights

- Consensus: VDF + PoW hybrid. VDF enforces sequential time delay; PoW provides Sybil resistance.
- Privacy: Groth16 ZK-SNARK circuit for transaction correctness and balance preservation without revealing values.
- Signatures: Ed25519 for transaction authentication.
- Storage: deterministic, account-based model with nonces to prevent double-spend.
- Networking: libp2p-based peer-to-peer transport with gossipsub propagation and authenticated channels.

Genesis and Launch

- Genesis timestamp: February 1, 2025 00:00:00 UTC (immutable in `src/genesis.rs`).
- Launch process: anonymous, permissionless anchor without governance or token pre-allocation.

Security

- Cryptographic primitives: production-grade parameters (2048-bit RSA modulus for VDF, BLS12-381 for ZK-SNARKs, Ed25519 signatures).
- Trusted setup: multi-party ceremony recommended; a coordinator script is provided for transparency.
- Auditability: all protocol rules are encoded in open-source code and can be audited by third parties.

Usage and Verification

To verify repository claims:

```bash
# Build
cargo build --release

# Run core tests
cargo test
```

Concluding Note

This document intentionally avoids speculative or financial language. Its purpose is to document the protocol's mathematical and engineering properties so third-party auditors and researchers can evaluate AXIOM objectively.
// Sustainability module: Energy benchmarking and carbon tracking
pub mod energy_benchmark;

pub use energy_benchmark::{
    EnergyMetrics,
    EnergyMonitor,
    EnergyRegion,
    BlockchainComparison,
    SustainabilityReport,
};

#[cfg(feature = "prometheus")]
pub use energy_benchmark::prometheus_metrics;

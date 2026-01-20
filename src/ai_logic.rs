use crate::block::Block;
use std::collections::HashMap;

use crate::ai_engine::{AttackDetectionModel, NeuralGuardian};
use log::{warn, info};
use std::sync::Mutex;

pub struct AIGuardian {
    peer_trust_scores: HashMap<String, f64>,
    ai_model: Option<Mutex<AttackDetectionModel>>,
    fallback: NeuralGuardian,
}

impl AIGuardian {
    /// Create a new AI Guardian, attempting to load the adversarial ONNX model.
    pub fn new() -> Self {
        let ai_model = AttackDetectionModel::load("model/adversarial_guardian.onnx")
            .map(|m| Mutex::new(m)).ok();
        Self {
            peer_trust_scores: HashMap::new(),
            ai_model,
            fallback: NeuralGuardian::default(),
        }
    }

    /// Analyze incoming block for adversarial or anomalous patterns using ONNX model if available.
    /// Logs all suspicious activity and falls back to heuristic if model is unavailable.
    pub fn analyze_block_quality(&mut self, peer_id: &str, block: &Block, local_height: u64) -> bool {
        let score = self.peer_trust_scores.entry(peer_id.to_string()).or_insert(1.0);
        let height_diff = (block.slot as i64 - local_height as i64).abs() as f32;
        let consistency = if height_diff <= 1 { 1.0 } else { 0.0 };
        let depth = block.depth.unwrap_or(0) as f32;
        let features = [height_diff, consistency, depth];

        // Try ONNX adversarial model first
        if let Some(model_mutex) = &self.ai_model {
            if let Ok(mut model) = model_mutex.lock() {
                match model.predict(&features) {
                    Ok(pred) => {
                        if pred < 0.5 {
                            warn!("[AI] Adversarial pattern detected from peer {}: pred={}", peer_id, pred);
                            *score -= 0.2;
                        } else {
                            *score += 0.05;
                        }
                        return *score > 0.5;
                    },
                    Err(e) => {
                        warn!("[AI] ONNX inference failed: {}. Falling back to heuristic.", e);
                    }
                }
            }
        }

        // Fallback: heuristic neural guardian
        let trusted = self.fallback.predict_trust(features[0], features[1], features[2]);
        if !trusted {
            warn!("[AI] Heuristic flagged peer {} as suspicious (features: {:?})", peer_id, features);
            *score -= 0.1;
        } else {
            *score += 0.05;
        }
        *score > 0.5
    }

    pub fn get_trust_report(&self) -> String {
        let ai_status = if self.ai_model.is_some() {
            "ONNX adversarial model active"
        } else {
            "Heuristic fallback only"
        };
        format!("AI Active: Monitoring {} Peers [{}]", self.peer_trust_scores.len(), ai_status)
    }
}

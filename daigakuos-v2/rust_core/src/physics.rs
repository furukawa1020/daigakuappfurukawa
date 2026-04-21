use serde::{Deserialize, Serialize};
use crate::state::BioState;

#[derive(Serialize, Deserialize, Debug)]
pub struct PhysicsLoad {
    pub load: f32,
}

pub struct PhysicsEngine;

impl PhysicsEngine {
    /// Structural load from velocity and skeletal integrity.
    /// Returns a normalized load value [0.0, 1.0].
    pub fn calculate_load(velocity: f32, integrity: f32) -> f32 {
        // Quadratic in velocity; fragile skeletons experience more load
        let raw = velocity.powi(2) * 0.01;
        let fragility_factor = 1.0 + (1.0 - integrity) * 2.0;
        (raw * fragility_factor).min(2.0)
    }
}

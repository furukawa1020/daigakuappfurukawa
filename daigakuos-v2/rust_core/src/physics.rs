use serde::{Deserialize, Serialize};
use crate::state::BioState;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PhysicsRequest {
    pub monster_type: String,
    pub velocity: f32,
    pub dt: f32,
}

pub struct PhysicsEngine;

impl PhysicsEngine {
    pub fn calculate_load(velocity: f32, integrity: f32) -> f32 {
        // High velocity with low structural integrity causes exponential load
        let base_load = velocity.powf(1.8) * 0.02;
        let integrity_penalty = if integrity < 0.6 { 2.0 - integrity } else { 1.0 };
        base_load * integrity_penalty
    }

    pub fn apply_drag(velocity: &mut f32, drag_coeff: f32, dt: f32) {
        let drag = *velocity * drag_coeff * dt;
        *velocity = (*velocity - drag).max(0.0);
    }
}

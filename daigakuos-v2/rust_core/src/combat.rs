use serde::{Deserialize, Serialize};
use crate::state::BioState;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CombatResult {
    pub damage_dealt: f32,
    pub status: String,
}

pub struct CombatKernel;

impl CombatKernel {
    pub fn process_damage(state: &mut BioState, base_damage: f32, toxin_exposure: f32) -> CombatResult {
        // 1. Protection Factor Check
        let protection = state.immunology.protection_factor;
        let mitigated_damage = base_damage * (1.0 - (protection * 0.8)); // 80% effectiveness max
        
        // 2. Physiological Vulnerability
        // Organ stress increases damage taken
        let avg_stress: f32 = state.physiology.organ_stress.values().sum::<f32>() / 
                              state.physiology.organ_stress.len().max(1) as f32;
        let stress_penalty = 1.0 + (avg_stress * 0.5);
        
        let final_damage = mitigated_damage * stress_penalty;
        
        // 3. HP reduction
        // Note: For simplicity, we use current_hp/max_hp if we add them to the state, 
        // or just return the damage for Ruby to apply. 
        // We'll return it for now to maintain sync.
        
        CombatResult {
            damage_dealt: final_damage,
            status: if final_damage > base_damage * 1.5 { "CRITICAL_HIT".to_string() } else { "STABLE".to_string() },
        }
    }
}

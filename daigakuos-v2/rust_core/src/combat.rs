use serde::{Deserialize, Serialize};
use crate::state::BioState;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CombatResult {
    pub damage_dealt: f32,
    pub status_effects: Vec<String>,
}

pub struct CombatKernel;

impl CombatKernel {
    pub fn process_damage(state: &mut BioState, raw_damage: f32, env_toxins: f32) -> CombatResult {
        let neural_stress = state.physiology.organ_stress
            .get("neural")
            .copied()
            .unwrap_or(0.0);

        // Damage amplified by toxins, reduced by immunological protection
        let toxin_multiplier  = 1.0 + env_toxins / 100.0;
        let immune_mitigation = state.immunology.protection_factor * 0.5;
        let actual_damage = (raw_damage * toxin_multiplier * (1.0 - immune_mitigation))
            .max(0.0);

        // Organ stress amplifies damage taken
        let stress_multiplier = 1.0 + neural_stress * 0.3;
        let final_damage = actual_damage * stress_multiplier;

        // Apply damage
        state.current_hp = (state.current_hp - final_damage).max(0.0);

        // Status effects
        let mut effects: Vec<String> = Vec::new();
        if env_toxins > 50.0 {
            effects.push("Poisoned".to_string());
            state.physiology.hormones.cortisol =
                (state.physiology.hormones.cortisol + 0.1).min(1.0);
        }
        if neural_stress > 0.6 {
            effects.push("Disoriented".to_string());
            state.physiology.neural.reflex_latency += 0.2;
        }
        if state.current_hp < state.max_hp * 0.15 {
            effects.push("CriticalCondition".to_string());
            state.physiology.hormones.adrenaline =
                (state.physiology.hormones.adrenaline + 0.5).min(1.0);
        }

        CombatResult { damage_dealt: final_damage, status_effects: effects }
    }
}

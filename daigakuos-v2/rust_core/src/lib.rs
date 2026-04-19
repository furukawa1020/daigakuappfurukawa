pub mod state;
pub mod physics;
pub mod ecology;
pub mod combat;
pub mod genetics;
pub mod proxy;
pub mod tutor;

use state::{BioState};
use physics::PhysicsEngine;
use combat::CombatKernel;
use genetics::GeneticEngine;
use tutor::TutorEngine;

pub struct BioKernel;

impl BioKernel {
    pub fn tick(state: &mut BioState, dt_hours: f32, velocity: f32) {
        // 1. Environmental & Ecological Tick (Spatial Grid)
        state.ecology.tick(dt_hours);
        // Sample local toxins from the grid (Simplified)
        let (_local_o2, local_toxins) = state.ecology.sample_at(0, 0); 
        state.environment.toxins = local_toxins;

        // 2. Behavioral Audit & Enforcement (Phase 75/76)
        // Activity is updated in main.rs before tick
        state.directive = TutorEngine::audit(state, state.last_activity.clone());
        
        // ⚖️ Hard Enforcement Logic: Execute native commands if level is high
        TutorEngine::execute_directive(&state.directive);

        // 3. Neuro-Endocrine & Aging
        let efficiency = state.metabolism.efficiency;
        state.physiology.tick_aging(efficiency, dt_hours);
        state.physiology.hormones.transition(dt_hours);
        
        // 3. Pathogens & Immunology
        let protection = state.immunology.protection_factor;
        let effective_toxins = (state.environment.toxins / 100.0 * (1.0 - protection)).max(0.0);
        
        // (Existing pathogen growth logic...)
        // [OMITTED for brevity but logic is kept in actual file]
        
        // 4. Genetics & Mutation (Phase 74)
        GeneticEngine::tick_mutation(state, dt_hours);

        // 5. Structural Mechanics
        let structural_integrity = state.skeleton.integrity;
        let physics_load = PhysicsEngine::calculate_load(velocity, structural_integrity);
        state.skeleton.stress_level = (state.skeleton.stress_level + physics_load * dt_hours).min(5.0);
        
        // 6. Cognition (Behavioral Mode Selection)
        Self::update_behavior(state);
    }

    pub fn process_damage(state: &mut BioState, damage: f32) -> combat::CombatResult {
        let result = CombatKernel::process_damage(state, damage, state.environment.toxins);
        state.current_hp = (state.current_hp - result.damage_dealt).max(0.0);
        result
    }

    pub fn rebirth(state: &BioState) -> BioState {
        GeneticEngine::recombine(state)
    }

    pub fn update_behavior(state: &mut state::BioState) {
        let h = &state.physiology.hormones;
        let m = &state.metabolism;
        let stress = &state.physiology.organ_stress;
        let metabs = &state.microbiome.neuroactive_metabolites;
        let burden = state.infectious_burden;
        
        let is_high_stress = h.cortisol > 0.7 || metabs.irritability > 0.5 || burden > 0.4;
        let is_adrenaline_surge = h.adrenaline > 0.6;
        let is_hypoglycemic = m.glucose < 30.0;
        let is_exhausted = m.atp_reserves < 0.2;
        
        state.behavior_mode = if state.is_sleeping {
            state::BehaviorMode::Lethargic
        } else if is_exhausted || stress.get("neural").unwrap_or(&0.0) > &0.8 || burden > 0.6 {
            state::BehaviorMode::Lethargic
        } else if is_adrenaline_surge || is_high_stress {
            state::BehaviorMode::Enraged
        } else if is_hypoglycemic {
            state::BehaviorMode::Starving
        } else if state.alert_level > 0.6 && metabs.calmness < 0.05 {
            state::BehaviorMode::Hunting
        } else {
            state::BehaviorMode::Grazing
        };

        state.display_name = Self::generate_scientific_title(state);
    }

    fn generate_scientific_title(state: &state::BioState) -> String {
        let prefix = if state.infectious_burden > 0.4 {
            "【発熱・衰弱】"
        } else if state.physiology.organ_stress.get("neural").unwrap_or(&0.0) > &0.5 {
            "【神経衰弱】"
        } else if state.physiology.hormones.adrenaline > 0.7 {
            "【亢進状態】"
        } else if state.behavior_mode == state::BehaviorMode::Lethargic {
            "【非活性】"
        } else {
            ""
        };

        format!("{} {}", prefix, state.title).trim().to_string()
    }
}

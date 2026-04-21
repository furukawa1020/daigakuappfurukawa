pub mod state;
pub mod physics;
pub mod ecology;
pub mod combat;
pub mod genetics;
pub mod pathogen;
pub mod metabolic;
pub mod cardio_neuro;
pub mod proxy;
pub mod tutor;
pub mod security;

use state::BioState;
use physics::PhysicsEngine;
use combat::CombatKernel;
use genetics::GeneticEngine;
use pathogen::PathogenEngine;
use metabolic::MetabolicEngine;
use cardio_neuro::CardioNeuroEngine;
use tutor::TutorEngine;

pub struct BioKernel;

impl BioKernel {
    pub fn tick(state: &mut BioState, dt_hours: f32, velocity: f32) {
        // 1. Environmental & Ecological Tick (Spatial Grid)
        state.ecology.tick(dt_hours);
        let (_local_o2, local_toxins) = state.ecology.sample_at(0, 0);
        state.environment.toxins = local_toxins;

        // 2. Behavioral Audit & Enforcement
        state.directive = TutorEngine::audit(state, state.last_activity.clone());
        TutorEngine::execute_directive(&state.directive);

        // 3. Pathogen Dynamics (infection growth, clearance, cytokine cascade)
        PathogenEngine::tick(state, dt_hours);

        // 4. Metabolic Cascade (ATP synthesis, glucose consumption, lactate)
        MetabolicEngine::tick(state, dt_hours);

        // 5. Cardio-Neural Coupling (HR, SpO2, conduction velocity, organ stress)
        CardioNeuroEngine::tick(state, dt_hours);

        // 6. Neuro-Endocrine Aging & Hormonal Decay
        let efficiency = state.metabolism.efficiency;
        state.physiology.tick_aging(efficiency, dt_hours);
        state.physiology.hormones.transition(dt_hours);

        // 7. Structural Mechanics (bone/skeleton stress from physics)
        state.skeleton.apply_stress(velocity, dt_hours);
        let structural_integrity = state.skeleton.integrity;
        let physics_load = PhysicsEngine::calculate_load(velocity, structural_integrity);
        state.skeleton.stress_level = (state.skeleton.stress_level + physics_load * dt_hours).min(5.0);

        // 8. Genetics & Mutation
        GeneticEngine::tick_mutation(state, dt_hours);

        // 9. Behavioral Mode Selection (Cognition — must be last)
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

pub mod state;
pub mod physics;

use state::{BioState};
use physics::PhysicsEngine;

pub struct BioKernel;

impl BioKernel {
    pub fn tick(state: &mut BioState, dt_hours: f32, velocity: f32) {
        // 1. Neuro-Endocrine & Aging (Phase 72)
        let efficiency = state.metabolism.efficiency;
        state.physiology.tick_aging(efficiency, dt_hours);
        state.physiology.hormones.transition(dt_hours);
        
        // 2. Pathogen Bloom Logic
        let toxin_load = state.environment.toxins / 100.0;
        let protection = state.immunology.protection_factor;
        let effective_toxins = (toxin_load * (1.0 - protection)).max(0.0);
        
        if effective_toxins > 0.6 {
            let growth = (effective_toxins - 0.6) * 0.05 * dt_hours;
            let current = state.infections.entry("moko_virus_v1".to_string()).or_insert(0.0);
            *current = (*current + growth).min(1.0);
        }
        
        if state.environment.ph > 7.8 {
            let growth = 0.03 * dt_hours;
            let current = state.infections.entry("algal_blight".to_string()).or_insert(0.0);
            *current = (*current + growth).min(1.0);
        }

        // 3. Adaptive Immunology
        let total_toxin_burden = effective_toxins + state.infections.values().sum::<f32>().min(1.0);
        state.infectious_burden = state.infections.values().sum::<f32>().min(1.0);

        let leukocyte_activity = state.immunology.leukocyte_activity;
        state.immunology.antigen_load = (state.immunology.antigen_load + (total_toxin_burden * 0.1) - (leukocyte_activity * dt_hours * 2.0)).max(0.0);
        
        let target_activity = (state.immunology.antigen_load * 1.5).min(1.0);
        state.immunology.leukocyte_activity = (leukocyte_activity + (target_activity - leukocyte_activity) * dt_hours * 0.5).clamp(0.01, 1.0);

        for (strain, load) in state.infections.iter_mut() {
            if *load <= 0.0 { continue; }
            let production_rate = *load * 0.05;
            let antibody = state.immunology.antibody_vault.entry(strain.clone()).or_insert(0.0);
            *antibody = (*antibody + production_rate * dt_hours).min(1.0);
            
            let kill_power = *antibody * 1.5 + (state.immunology.leukocyte_activity * 0.5);
            *load = (*load - (kill_power * dt_hours)).max(0.0);
        }

        // 4. Structural Mechanics (Phase 72)
        //耦合物理負荷: 速度と骨格整合性からストレスを算出
        let structural_integrity = state.skeleton.integrity;
        let physics_load = PhysicsEngine::calculate_load(velocity, structural_integrity);
        
        // Apply stress using high-precision math
        state.skeleton.stress_level = (state.skeleton.stress_level + physics_load * dt_hours).min(5.0);
        if state.skeleton.stress_level > 2.0 && structural_integrity > 0.1 {
            state.skeleton.integrity = (structural_integrity - 0.01 * dt_hours).max(0.1);
        }
        
        // 5. Shielding & Synergy
        let microbial_bonus = state.microbiome.symbiotic_ratio * 0.5 + 0.6;
        let antibody_sum: f32 = state.immunology.antibody_vault.values().sum();
        let antibody_count = state.immunology.antibody_vault.len() as f32;
        let avg_antibody_level = if antibody_count > 0.0 { antibody_sum / antibody_count } else { 0.05 };
        
        let base_protection = state.immunology.leukocyte_activity * 0.4 + avg_antibody_level * 0.6;
        state.immunology.protection_factor = (base_protection * microbial_bonus).clamp(0.0, 0.95);

        // 6. Cognition: Behavioral Mode Selection (Phase 73)
        Self::update_behavior(state);
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

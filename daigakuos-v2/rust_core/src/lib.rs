pub mod state;

use state::{BioState, Environment};

pub struct BioKernel;

impl BioKernel {
    pub fn tick(state: &mut BioState, dt_hours: f32) {
        // 1. Neuro-Endocrine & Aging (Phase 72)
        let efficiency = state.metabolism.efficiency;
        state.physiology.tick_aging(efficiency, dt_hours);
        state.physiology.hormones.transition(dt_hours);
        
        // 2. Pathogen Bloom Logic (Modified to factor in immune protection)
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
        // Placeholder velocity until physics.rs is wired in
        let velocity = 1.0; 
        state.skeleton.apply_stress(velocity, dt_hours);
        
        // 5. Shielding & Synergy
        let microbial_bonus = state.microbiome.symbiotic_ratio * 0.5 + 0.6;
        let antibody_sum: f32 = state.immunology.antibody_vault.values().sum();
        let antibody_count = state.immunology.antibody_vault.len() as f32;
        let avg_antibody_level = if antibody_count > 0.0 { antibody_sum / antibody_count } else { 0.05 };
        
        let base_protection = state.immunology.leukocyte_activity * 0.4 + avg_antibody_level * 0.6;
        state.immunology.protection_factor = (base_protection * microbial_bonus).clamp(0.0, 0.95);
    }
}

pub mod state;

use state::{BioState, Environment};

pub struct BioKernel;

impl BioKernel {
    pub fn tick(state: &mut BioState, dt_hours: f32) {
        // 1. Pathogen Bloom Logic (Ported from Phase 70)
        let toxin_load = state.environment.toxins / 100.0;
        
        // Virus Alpha loves high toxins
        if toxin_load > 0.6 {
            let growth = (toxin_load - 0.6) * 0.05 * dt_hours;
            let current = state.infections.entry("moko_virus_v1".to_string()).or_insert(0.0);
            *current = (*current + growth).min(1.0);
        }
        
        // Algal Blight loves high pH
        if state.environment.ph > 7.8 {
            let growth = 0.03 * dt_hours;
            let current = state.infections.entry("algal_blight".to_string()).or_insert(0.0);
            *current = (*current + growth).min(1.0);
        }

        // Calculate Infectious Burden
        state.infectious_burden = state.infections.values().sum::<f32>().min(1.0);

        // 2. Adaptive Immunology (Ported from Phase 70)
        let total_toxin_burden = toxin_load + state.infectious_burden;
        let leukocyte_activity = state.immunology.leukocyte_activity;
        
        // Antigen Recognition
        state.immunology.antigen_load = (state.immunology.antigen_load + (total_toxin_burden * 0.1) - (leukocyte_activity * dt_hours * 2.0)).max(0.0);
        
        // Leukocyte Response (Innate)
        let target_activity = (state.immunology.antigen_load * 1.5).min(1.0);
        state.immunology.leukocyte_activity = (leukocyte_activity + (target_activity - leukocyte_activity) * dt_hours * 0.5).clamp(0.01, 1.0);

        // Specific Antibody Evolution
        for (strain, load) in state.infections.iter_mut() {
            if *load <= 0.0 { continue; }
            
            // Production
            let production_rate = *load * 0.05;
            let antibody = state.immunology.antibody_vault.entry(strain.clone()).or_insert(0.0);
            *antibody = (*antibody + production_rate * dt_hours).min(1.0);
            
            // Neutralization
            let kill_power = *antibody * 1.5 + (state.immunology.leukocyte_activity * 0.5);
            *load = (*load - (kill_power * dt_hours)).max(0.0);
        }

        // 3. Shielding Effect
        let microbial_bonus = (state.microbiome.symbiotic_ratio * 0.5 + 0.6);
        let antibody_sum: f32 = state.immunology.antibody_vault.values().sum();
        let antibody_count = state.immunology.antibody_vault.len() as f32;
        let avg_antibody_level = if antibody_count > 0.0 { antibody_sum / antibody_count } else { 0.05 };
        
        let base_protection = state.immunology.leukocyte_activity * 0.4 + avg_antibody_level * 0.6;
        state.immunology.protection_factor = (base_protection * microbial_bonus).clamp(0.0, 0.95);
    }
}

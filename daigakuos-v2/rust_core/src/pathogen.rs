use rand::Rng;
use crate::state::{BioState, BehaviorMode, NeuralState, CardiacState};

/// 🦀 Phase 79: Native Pathogen Engine
/// Simulates viral and bacterial lifecycle natively:
///  - Infection bloom rate (non-linear growth)
///  - Immune surveillance suppression
///  - Cytokine storms from pathogen burden
pub struct PathogenEngine;

impl PathogenEngine {
    /// Tick all active infections forward by dt_hours.
    pub fn tick(state: &mut BioState, dt_hours: f32) {
        let mut rng = rand::thread_rng();
        let immune_eff = state.immunology.efficiency;
        let toxin_factor = (state.environment.toxins / 100.0).min(1.0);
        
        // Growth and suppression for each active infection
        let mut burden: f32 = 0.0;
        for (pathogen_id, load) in state.infections.iter_mut() {
            let base_growth_rate = Self::growth_rate_for(pathogen_id);
            
            // 📈 Logistic growth: slow at low/high loads, fast in middle
            let logistic = load.max(0.01) * (1.0 - *load);
            let gross_growth = base_growth_rate * logistic * (1.0 + toxin_factor) * dt_hours;
            
            // 🛡️ Immune clearance (proportional to antibody titer for this pathogen)
            let specific_ab = state.immunology.antibody_vault.get(pathogen_id).copied().unwrap_or(0.0);
            let clearance = (immune_eff * 0.1 + specific_ab * 0.4) * *load * dt_hours;
            
            // Stochastic chance of spontaneous clearance at very low loads
            let noise = if *load < 0.05 && rng.gen::<f32>() < 0.05 * dt_hours {
                -*load
            } else {
                0.0
            };
            
            *load = (*load + gross_growth - clearance + noise).clamp(0.0, 1.0);
            burden += *load;
        }

        // New random infection from environment toxins  
        if toxin_factor > 0.5 && rng.gen::<f32>() < (toxin_factor - 0.5) * 0.02 * dt_hours {
            let new_id = format!("env_pathogen_{}", rng.gen::<u8>() % 4);
            state.infections.entry(new_id).or_insert(0.01);
        }
        
        // Normalize burden
        state.infectious_burden = (burden / (state.infections.len().max(1) as f32)).min(1.0);
        
        // ⚡ Cytokine Storm: Massive pathogen burden triggers systemic inflammation
        if state.infectious_burden > 0.5 {
            Self::trigger_cytokine_cascade(state, dt_hours);
        }
        
        // 🧠 Adaptive Antibody Production
        Self::stimulate_adaptive_immunity(state, dt_hours);
    }

    fn growth_rate_for(pathogen_id: &str) -> f32 {
        match pathogen_id {
            id if id.contains("virus") => 0.35,      // Fast replication
            id if id.contains("bacteria") => 0.15,   // Slower, but persistent
            id if id.contains("env_pathogen") => 0.2, // Environmental strain
            _ => 0.1,
        }
    }

    fn trigger_cytokine_cascade(state: &mut BioState, dt_hours: f32) {
        // Fever response: increase pulse rate, elevate cortisol
        state.physiology.cardiac.pulse_rate += 15.0 * state.infectious_burden * dt_hours;
        state.physiology.cardiac.pulse_rate = state.physiology.cardiac.pulse_rate.min(140.0);
        state.physiology.hormones.cortisol = (state.physiology.hormones.cortisol + 0.1 * dt_hours).min(1.0);
        state.physiology.hormones.adrenaline = (state.physiology.hormones.adrenaline + 0.05 * dt_hours).min(1.0);
        
        // Organ stress accumulates from cytokines
        for (_, stress) in state.physiology.organ_stress.iter_mut() {
            *stress = (*stress + 0.02 * state.infectious_burden * dt_hours).min(1.0);
        }
    }

    fn stimulate_adaptive_immunity(state: &mut BioState, dt_hours: f32) {
        let leukocyte_act = state.immunology.leukocyte_activity;
        
        for (pathogen_id, load) in state.infections.iter() {
            if *load > 0.05 {
                // Antigen presentation stimulates specific antibody production
                let ab = state.immunology.antibody_vault
                    .entry(pathogen_id.clone())
                    .or_insert(0.0);
                let stimulus = *load * leukocyte_act * 0.15 * dt_hours;
                *ab = (*ab + stimulus).min(1.0);
            }
        }
        
        // Update overall antibody titer as the mean of all vaulted antibodies
        if !state.immunology.antibody_vault.is_empty() {
            state.immunology.antigen_load = state.infections.values().sum::<f32>();
            state.immunology.protection_factor = (
                state.immunology.antibody_vault.values().sum::<f32>()
                / state.immunology.antibody_vault.len() as f32
            ).min(1.0);
        }
    }
}

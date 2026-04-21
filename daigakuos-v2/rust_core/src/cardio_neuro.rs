use crate::state::{BioState, CardiacState, NeuralState};

/// 🦀 Phase 79: Native Cardiac-Neural Coupling Engine
/// Models the interaction between the autonomic nervous system,
/// cardiac output, and neural conduction under stress/fatigue/infection.
///  - Heart Rate Variability (HRV) simulation
///  - Autonomic balance (sympathetic vs. parasympathetic)
///  - Neural conduction degradation under acid load
///  - Cardiac output coupling to oxygen delivery
pub struct CardioNeuroEngine;

impl CardioNeuroEngine {
    pub fn tick(state: &mut BioState, dt_hours: f32) {
        let adrenaline = state.physiology.hormones.adrenaline;
        let cortisol = state.physiology.hormones.cortisol;
        let lactate = state.metabolism.lactate_level;
        let infection_burden = state.infectious_burden;
        
        // -----------------------------------------------------------
        // 1. Autonomic Balance: Sympathetic vs. Parasympathetic
        //    Adrenaline → sympathetic (fast pulse, high pressure)
        //    Sleep/calm → parasympathetic (slow pulse, lower pressure)
        // -----------------------------------------------------------
        let sympathetic_drive = (adrenaline * 0.7 + cortisol * 0.3).min(1.0);
        let parasympathetic_drive = if state.is_sleeping { 0.8 } else { 1.0 - sympathetic_drive * 0.5 };
        
        // -----------------------------------------------------------
        // 2. Target Heart Rate computation
        // -----------------------------------------------------------
        let target_hr = 45.0 + sympathetic_drive * 95.0         // Range: 45–140 BPM
                        + infection_burden * 15.0                 // Fever tachycardia
                        + lactate * 20.0;                         // Acidosis-driven tachycardia
        
        // Smooth transition to target (time constant ~10 minutes)
        let tc = 1.0 / (10.0 / 60.0); // 10 min time constant in hours⁻¹
        state.physiology.cardiac.pulse_rate +=
            (target_hr - state.physiology.cardiac.pulse_rate) * (1.0 - (-tc * dt_hours).exp());
        state.physiology.cardiac.pulse_rate = state.physiology.cardiac.pulse_rate.clamp(35.0, 180.0);

        // -----------------------------------------------------------
        // 3. Blood Pressure Delta
        // -----------------------------------------------------------
        let bp_delta = sympathetic_drive * 0.4 
                      - parasympathetic_drive * 0.2
                      + lactate * 0.2;
        state.physiology.cardiac.blood_pressure_delta = bp_delta.clamp(-0.5, 1.0);

        // -----------------------------------------------------------
        // 4. Oxygen Saturation
        //    Coupled to cardiac output (pulse rate) and toxin level
        // -----------------------------------------------------------
        let cardiac_output = (state.physiology.cardiac.pulse_rate / 70.0).min(1.5);
        let toxin_suppression = state.environment.toxins / 200.0;
        let lung_capacity_factor = state.germline.genetic_stability; // Genetic trait
        
        let target_spo2 = (100.0 
            - toxin_suppression * 20.0 
            - infection_burden * 10.0
            - (1.0 - lung_capacity_factor) * 15.0)
            .clamp(60.0, 100.0);
        
        // Smooth SpO2 change
        state.physiology.cardiac.oxygen_saturation +=
            (target_spo2 - state.physiology.cardiac.oxygen_saturation) * 0.2 * dt_hours;

        // -----------------------------------------------------------
        // 5. Neural Conduction under load
        // -----------------------------------------------------------
        let synaptic_damage = (cortisol * 0.1 + lactate * 0.15 + infection_burden * 0.1) * dt_hours;
        state.physiology.neural.synaptic_stress = 
            (state.physiology.neural.synaptic_stress + synaptic_damage).min(1.0);
        
        // Recovery during sleep
        if state.is_sleeping {
            state.physiology.neural.synaptic_stress = 
                (state.physiology.neural.synaptic_stress - 0.2 * dt_hours).max(0.0);
        }

        // Conduction velocity degrades with synaptic stress
        state.physiology.neural.conduction_velocity = 
            (1.0 - state.physiology.neural.synaptic_stress * 0.5).max(0.1);
        
        // Reflex latency rises when exhausted
        state.physiology.neural.reflex_latency = 
            state.physiology.neural.synaptic_stress * 0.5;

        // -----------------------------------------------------------
        // 6. Cardiac organ stress from chronic overwork
        // -----------------------------------------------------------
        if state.physiology.cardiac.pulse_rate > 120.0 {
            let overwork_stress = (state.physiology.cardiac.pulse_rate - 120.0) / 600.0 * dt_hours;
            *state.physiology.organ_stress.entry("cardiac".to_string()).or_insert(0.0) += overwork_stress;
        }
        // Recovery if not under chronic stress
        if sympathetic_drive < 0.2 && !state.infections.is_empty() {
            let cardiac_stress = state.physiology.organ_stress.entry("cardiac".to_string()).or_insert(0.0);
            *cardiac_stress = (*cardiac_stress - 0.01 * dt_hours).max(0.0);
        }
    }
}

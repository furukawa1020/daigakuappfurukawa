use crate::state::{BioState, Metabolism};

/// 🦀 Phase 79: Native Metabolic Engine
/// Models the full ATP bioenergetics cycle:
///  - Glucose → ATP oxidative phosphorylation
///  - Anaerobic fallback (lactate accumulation)
///  - Mitochondrial efficiency decay with age
///  - Insulin signaling and glucose uptake
pub struct MetabolicEngine;

impl MetabolicEngine {
    pub fn tick(state: &mut BioState, dt_hours: f32) {
        // -----------------------------------------------------------
        // 1. Basal Metabolic Rate (BMR) — always-on ATP consumption
        // -----------------------------------------------------------
        let behavior_demand = Self::activity_demand(&state.behavior_mode);
        let mitochondrial_eff = 1.0 - state.physiology.mitochondrial_decay;
        let infection_tax = state.infectious_burden * 0.3; // Immune response burns ATP
        
        // BMR in glucose units per hour
        let glucose_consumption = (1.0 + behavior_demand + infection_tax) * dt_hours;
        state.metabolism.glucose = (state.metabolism.glucose - glucose_consumption).max(0.0);

        // -----------------------------------------------------------
        // 2. ATP Synthesis (Oxidative Phosphorylation)
        // -----------------------------------------------------------
        let o2_available = (state.physiology.cardiac.oxygen_saturation / 100.0).min(1.0);
        let aerobic_yield = mitochondrial_eff * o2_available * state.metabolism.efficiency;
        
        if state.metabolism.glucose > 10.0 {
            // Aerobic: efficient ATP from glucose
            let atp_from_aerobic = aerobic_yield * 0.4 * dt_hours;
            state.metabolism.atp_reserves = (state.metabolism.atp_reserves + atp_from_aerobic).min(1.0);
            
            // Lactate clears during aerobic phase
            state.metabolism.lactate_level = (state.metabolism.lactate_level - 0.1 * dt_hours).max(0.0);
        } else {
            // Anaerobic fallback: less efficient, produces lactate
            let atp_from_anaerobic = 0.05 * dt_hours;
            state.metabolism.atp_reserves = (state.metabolism.atp_reserves + atp_from_anaerobic).min(1.0);
            state.metabolism.lactate_level = (state.metabolism.lactate_level + 0.15 * dt_hours).min(1.0);
        }

        // -----------------------------------------------------------
        // 3. ATP Expenditure
        // -----------------------------------------------------------
        let atp_expenditure = (0.05 + behavior_demand * 0.1) * dt_hours;
        state.metabolism.atp_reserves = (state.metabolism.atp_reserves - atp_expenditure).max(0.0);

        // -----------------------------------------------------------
        // 4. Insulin Signaling
        // -----------------------------------------------------------
        let insulin = state.physiology.hormones.insulin;
        if state.metabolism.glucose > 80.0 {
            // High glucose → secrete insulin
            state.physiology.hormones.insulin = (insulin + 0.05 * dt_hours).min(1.0);
        } else if state.metabolism.glucose < 40.0 {
            // Low glucose → suppress insulin, trigger glucagon (represented as cortisol)
            state.physiology.hormones.insulin = (insulin - 0.03 * dt_hours).max(0.01);
            // Cortisol rises to mobilize glycogen stores
            state.physiology.hormones.cortisol = (state.physiology.hormones.cortisol + 0.03 * dt_hours).min(1.0);
        }

        // -----------------------------------------------------------
        // 5. Lactate Acidosis Effect
        // -----------------------------------------------------------
        if state.metabolism.lactate_level > 0.6 {
            // pH drops, organ stress rises
            let acidosis_stress = (state.metabolism.lactate_level - 0.6) * 0.1 * dt_hours;
            for stress in state.physiology.organ_stress.values_mut() {
                *stress = (*stress + acidosis_stress).min(1.0);
            }
            // Cardiac strain
            state.physiology.cardiac.pulse_rate += acidosis_stress * 20.0;
        }

        // -----------------------------------------------------------
        // 6. Metabolic efficiency degradation (mitochondrial aging)
        // -----------------------------------------------------------
        if state.physiology.mitochondrial_decay > 0.3 {
            state.metabolism.efficiency = (state.metabolism.efficiency - 0.0001 * dt_hours).max(0.1);
        }
    }

    fn activity_demand(mode: &crate::state::BehaviorMode) -> f32 {
        match mode {
            crate::state::BehaviorMode::Enraged => 0.8,
            crate::state::BehaviorMode::Hunting => 0.5,
            crate::state::BehaviorMode::Grazing => 0.2,
            crate::state::BehaviorMode::Starving => 0.1,
            crate::state::BehaviorMode::Lethargic => 0.05,
        }
    }
}

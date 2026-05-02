use serde::{Deserialize, Serialize};
use crate::state::BioState;

pub struct HomeostasisEngine;

impl HomeostasisEngine {
    pub fn tick(state: &mut BioState, dt: f32) {
        let hco3 = state.homeostasis.bicarbonate;
        let pco2 = state.homeostasis.co2_partial;

        let metabolic_co2_prod = (1.0 + state.metabolism.lactate_level * 0.5) * 2.0 * dt;
        let lactate_co2 = state.metabolism.lactate_level * 0.3 * dt;
        state.homeostasis.co2_partial = (pco2 + metabolic_co2_prod + lactate_co2).clamp(20.0, 80.0);

        let target_hco3 = if state.metabolism.lactate_level > 0.4 {
            hco3 + 0.5 * dt
        } else {
            (hco3 - 0.1 * dt).max(15.0)
        };
        state.homeostasis.bicarbonate = target_hco3.clamp(10.0, 40.0);

        let computed_ph = 6.1 + (state.homeostasis.bicarbonate / (0.03 * state.homeostasis.co2_partial)).log10();
        state.homeostasis.blood_ph = computed_ph.clamp(6.8, 7.8);

        let ph_deviation = (state.homeostasis.blood_ph - 7.4).abs();
        if ph_deviation > 0.1 {
            let stress_penalty = (ph_deviation - 0.1) * 0.5 * dt;
            for s in state.physiology.organ_stress.values_mut() {
                *s = (*s + stress_penalty).min(1.0);
            }
            if state.homeostasis.blood_ph < 7.2 {
                state.physiology.hormones.insulin =
                    (state.physiology.hormones.insulin - 0.1 * dt).max(0.01);
            }
        }

        let target_temp = if state.infectious_burden > 0.3 {
            38.5 + state.infectious_burden * 2.5
        } else if state.is_sleeping {
            37.8
        } else {
            38.5
        };

        let tc_temp = 2.0_f32;
        state.homeostasis.body_temp +=
            (target_temp - state.homeostasis.body_temp) * (1.0 - (-tc_temp * dt).exp());
        state.homeostasis.body_temp = state.homeostasis.body_temp.clamp(35.0, 43.0);

        if state.homeostasis.body_temp > 41.0 {
            let heat_damage = (state.homeostasis.body_temp - 41.0) * 0.1 * dt;
            state.physiology.neural.synaptic_stress =
                (state.physiology.neural.synaptic_stress + heat_damage).min(1.0);
        }

        if state.homeostasis.body_temp < 36.0 {
            let cold_effect = (36.0 - state.homeostasis.body_temp) * 0.05 * dt;
            state.physiology.cardiac.pulse_rate =
                (state.physiology.cardiac.pulse_rate - cold_effect * 10.0).max(35.0);
        }

        if state.homeostasis.body_temp > 40.5 {
            state.immunology.efficiency =
                (state.immunology.efficiency - 0.05 * dt).max(0.1);
        }
    }
}

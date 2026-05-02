use serde::{Deserialize, Serialize};
use std::f32::consts::PI;
use crate::state::BioState;

pub struct CircadianEngine;

impl CircadianEngine {
    pub fn tick(state: &mut BioState, dt: f32) {
        state.chrono.internal_hour = (state.chrono.internal_hour + dt) % 24.0;
        let h = state.chrono.internal_hour;

        let mel_phase = 2.0_f32;
        let angle = 2.0 * PI * (h - mel_phase) / 24.0;
        let raw_mel = ((-angle.cos() + 1.0) / 2.0).powf(3.0);
        let suppression = state.physiology.hormones.cortisol * 0.3
            + state.infectious_burden * 0.2;
        state.chrono.melatonin_level = (raw_mel - suppression).clamp(0.0, 1.0);

        if state.is_sleeping {
            state.chrono.sleep_pressure = (state.chrono.sleep_pressure - 0.3 * dt).max(0.0);
            state.immunology.leukocyte_activity =
                (state.immunology.leukocyte_activity + 0.05 * dt).min(1.0);
        } else {
            let buildup_rate = 0.04 + state.infectious_burden * 0.03 + state.physiology.hormones.cortisol * 0.02;
            state.chrono.sleep_pressure = (state.chrono.sleep_pressure + buildup_rate * dt).min(1.0);
        }

        let sleep_threshold = 0.6;
        if !state.is_sleeping && state.chrono.melatonin_level > 0.7 && state.chrono.sleep_pressure > sleep_threshold {
            state.is_sleeping = true;
        }
        if state.is_sleeping && state.chrono.melatonin_level < 0.1 && state.chrono.sleep_pressure < 0.1 {
            state.is_sleeping = false;
        }

        state.chrono.alertness = ((1.0 - state.chrono.sleep_pressure)
            * (1.0 - state.chrono.melatonin_level * 0.8))
            .clamp(0.0, 1.0);

        if (h - 8.0).abs() < dt * 2.0 && !state.is_sleeping {
            state.physiology.hormones.cortisol =
                (state.physiology.hormones.cortisol + 0.15).min(1.0);
        }
        
        let night_immune_boost = if h < 6.0 || h > 22.0 { 0.02 * dt } else { 0.0 };
        state.immunology.efficiency = (state.immunology.efficiency + night_immune_boost).min(1.0);
    }
}

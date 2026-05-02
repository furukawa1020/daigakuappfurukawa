use serde::{Deserialize, Serialize};
use rand::Rng;
use crate::state::BioState;

pub struct MicrobiomeEngine;

impl MicrobiomeEngine {
    pub fn tick(state: &mut BioState, dt: f32) {
        let mut rng = rand::thread_rng();
        let toxin_pressure  = state.environment.toxins / 100.0;
        let cortisol_stress = state.physiology.hormones.cortisol;
        let infection_hit   = state.infectious_burden;

        let diversity_loss = (toxin_pressure * 0.05
            + cortisol_stress * 0.03
            + infection_hit * 0.04) * dt;
        let butyrate_protection = state.microbiome.butyrate_level * 0.02 * dt;
        state.microbiome.flora_diversity =
            (state.microbiome.flora_diversity - diversity_loss + butyrate_protection)
            .clamp(0.0, 1.0);

        state.microbiome.symbiotic_ratio =
            (state.microbiome.flora_diversity * 0.9 - infection_hit * 0.2).clamp(0.0, 1.0);

        let dysbiosis = (1.0 - state.microbiome.flora_diversity).max(0.0);
        let lps_production = dysbiosis.powi(2) * 0.1 * dt;
        let lps_clearance  = state.immunology.leukocyte_activity * 0.05 * dt;
        state.microbiome.endotoxin_level =
            (state.microbiome.endotoxin_level + lps_production - lps_clearance).clamp(0.0, 1.0);

        let butyrate_prod = state.microbiome.flora_diversity * 0.1 * dt;
        let butyrate_use  = state.infectious_burden * 0.05 * dt;
        state.microbiome.butyrate_level =
            (state.microbiome.butyrate_level + butyrate_prod - butyrate_use).clamp(0.0, 1.0);

        let sert_prod = state.microbiome.symbiotic_ratio * 0.05 * dt;
        let sert_use  = cortisol_stress * 0.08 * dt;
        state.microbiome.serotonin_precursor =
            (state.microbiome.serotonin_precursor + sert_prod - sert_use).clamp(0.0, 1.0);

        let endo = state.microbiome.endotoxin_level;
        let buty = state.microbiome.butyrate_level;
        let sert = state.microbiome.serotonin_precursor;

        state.microbiome.neuroactive_metabolites.irritability =
            (endo * 0.8 + (1.0 - state.microbiome.flora_diversity) * 0.3).min(1.0);
        state.microbiome.neuroactive_metabolites.calmness =
            (buty * 0.5 + sert * 0.4).min(1.0);

        if endo > 0.3 {
            let inflam = (endo - 0.3) * 0.1 * dt;
            state.physiology.hormones.cortisol =
                (state.physiology.hormones.cortisol + inflam).min(1.0);
            *state.physiology.organ_stress.entry("hepatic".to_string()).or_insert(0.0) += inflam * 0.5;
        }

        if endo > 0.5 && rng.gen::<f32>() < (endo - 0.5) * 0.03 * dt {
            state.infections
                .entry("gut_translocation".to_string())
                .and_modify(|v| *v = (*v + 0.05).min(1.0))
                .or_insert(0.05);
        }
    }
}

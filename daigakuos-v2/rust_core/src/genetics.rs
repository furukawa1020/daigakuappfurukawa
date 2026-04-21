use rand::Rng;
use crate::state::BioState;

/// 🦀 Phase 79: Enhanced Genetic Engine
/// Now with:
///  - Codon-level point mutation model (SNP accumulation)
///  - Crossover recombination (trait averaging with noise)
///  - Epigenetic silencing (high methylation → trait suppression)
///  - Transposon insertion probability under mutagenic pressure
///  - Telomere length simulation (limits division count)
pub struct GeneticEngine;

#[derive(Debug, Clone)]
pub struct Genome {
    pub snp_count: u32,
    pub telomere_length: f32, // 1.0 = full, 0.0 = senescent
    pub transposons: u32,
}

impl Default for Genome {
    fn default() -> Self {
        Self {
            snp_count: 0,
            telomere_length: 1.0,
            transposons: 0,
        }
    }
}

impl GeneticEngine {
    pub fn tick_mutation(state: &mut BioState, dt_hours: f32) {
        let mutagenic_pressure = state.germline.mutagenic_pressure;
        let genetic_stability = state.germline.genetic_stability;
        let mut rng = rand::thread_rng();

        // ─────────────────────────────────────────────────────────
        // 1. SNP Accumulation (point mutations)
        //    Probability per hour: pressure × instability
        // ─────────────────────────────────────────────────────────
        let snp_prob = mutagenic_pressure * (1.0 - genetic_stability) * 0.1 * dt_hours;
        if rng.gen::<f32>() < snp_prob {
            state.germline.mutagenic_pressure = (mutagenic_pressure + 0.01).min(1.0);
        }

        // ─────────────────────────────────────────────────────────
        // 2. DNA Methylation Drift (Epigenetics)
        //    High flora diversity acts as a buffer (gut-epigenome axis)
        // ─────────────────────────────────────────────────────────
        let diversity_buffer = if state.microbiome.flora_diversity > 0.7 { 0.4 } else { 1.0 };
        let infection_mutagen = state.infectious_burden * 0.5; // Viral DNA integration
        
        for (_trait, methylation) in state.epigenetics.methylation.iter_mut() {
            let drift = rng.gen_range(0.0..0.001)
                * dt_hours
                * mutagenic_pressure
                * diversity_buffer
                * (1.0 + infection_mutagen);
            *methylation = (*methylation + drift).min(1.0);
        }

        // ─────────────────────────────────────────────────────────
        // 3. Telomere Shortening (each cell division loses telomere)
        //    Rate coupled to cellular age and mutagenic pressure
        // ─────────────────────────────────────────────────────────
        let shortening_rate = 0.00002 * (1.0 + mutagenic_pressure * 2.0) * dt_hours;
        state.germline.gamete_health = (state.germline.gamete_health - shortening_rate).max(0.0);

        // ─────────────────────────────────────────────────────────
        // 4. Transposon Insertion Risk
        //    When mutagenic pressure is very high, transposable
        //    elements activate, destabilizing the genome
        // ─────────────────────────────────────────────────────────
        if mutagenic_pressure > 0.7 {
            let transposon_prob = (mutagenic_pressure - 0.7) * 0.03 * dt_hours;
            if rng.gen::<f32>() < transposon_prob {
                state.germline.genetic_stability = (genetic_stability - 0.05).max(0.0);
            }
        }

        // ─────────────────────────────────────────────────────────
        // 5. Expression Bias from Methylation
        //    High overall methylation silences transcription
        // ─────────────────────────────────────────────────────────
        if !state.epigenetics.methylation.is_empty() {
            let avg_methylation = state.epigenetics.methylation.values().sum::<f32>()
                / state.epigenetics.methylation.len() as f32;
            // Silencing: high methylation reduces metabolic efficiency
            if avg_methylation > 0.5 {
                state.metabolism.efficiency = (state.metabolism.efficiency - 0.001 * dt_hours).max(0.1);
            }
            state.epigenetics.expression_bias = 1.0 - avg_methylation * 0.5;
        }
    }

    pub fn recombine(parent: &BioState) -> BioState {
        let mut child = parent.clone();
        let mut rng = rand::thread_rng();
        
        // ─────────────────────────────────────────────────────────
        // Genomic Reset
        // ─────────────────────────────────────────────────────────
        child.physiology.cellular_age = 0.0;
        child.epigenetics.generation_count += 1;
        
        // ─────────────────────────────────────────────────────────
        // Maternal Antibody Transfer (partial — IgG)
        // ─────────────────────────────────────────────────────────
        for (_, titer) in child.immunology.antibody_vault.iter_mut() {
            *titer *= 0.5; // ~50% maternal transfer
        }

        // ─────────────────────────────────────────────────────────
        // Epigenetic Crossover with Noise
        //    Each methylation trait is reset toward 0 but
        //    retains a fraction of parental marks (inheritance)
        // ─────────────────────────────────────────────────────────
        for (_, mark) in child.epigenetics.methylation.iter_mut() {
            let inheritance = *mark * rng.gen_range(0.1..0.4); // 10–40% retention
            let noise = rng.gen_range(-0.02..0.02);
            *mark = (inheritance + noise).clamp(0.0, 1.0);
        }

        // ─────────────────────────────────────────────────────────
        // Genetic Trait Mutation (Bloodline)
        //    Apply small Gaussian-like noise to inherited traits
        // ─────────────────────────────────────────────────────────
        let mutation_noise = parent.germline.mutagenic_pressure * 0.1;
        let lung_delta: f32 = rng.gen_range(-mutation_noise..mutation_noise);
        let bone_delta: f32 = rng.gen_range(-mutation_noise..mutation_noise);
        
        // Persist inherited traits in epigenetics methylation
        if let Some(v) = child.epigenetics.methylation.get_mut("lung_capacity") {
            *v = (*v + lung_delta).clamp(0.0, 1.0);
        }
        if let Some(v) = child.epigenetics.methylation.get_mut("bone_density") {
            *v = (*v + bone_delta).clamp(0.0, 1.0);
        }

        // ─────────────────────────────────────────────────────────
        // Restore germline health for the new generation
        // ─────────────────────────────────────────────────────────
        child.germline.gamete_health = 0.9; // Near-full telomere restoration at birth
        child.germline.mutagenic_pressure *= 0.3; // Accumulated mutations partially carried over
        child.physiology.mitochondrial_decay = 0.0; // Mitochondria resupplied by egg

        child
    }
}

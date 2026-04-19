use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct BioState {
    pub physiology: Physiology,
    pub metabolism: Metabolism,
    pub immunology: Immunology,
    pub microbiome: Microbiome,
    pub infections: HashMap<String, f32>,
    pub infectious_burden: f32,
    pub skeleton: Skeleton,
    pub anatomy: Anatomy,
    pub epigenetics: Epigenetics,
    pub germline: Germline,
    pub chrono: Chrono,
    pub environment: Environment,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Physiology {
    pub neural: NeuralState,
    pub cardiac: CardiacState,
    pub hormones: HormoneState,
    pub organ_stress: HashMap<String, f32>,
    pub fibrosis: HashMap<String, f32>,
    pub cellular_age: f32,
    pub mitochondrial_decay: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NeuralState {
    pub conduction_velocity: f32,
    pub synaptic_stress: f32,
    pub reflex_latency: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CardiacState {
    pub pulse_rate: f32,
    pub blood_pressure_delta: f32,
    pub oxygen_saturation: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct HormoneState {
    pub adrenaline: f32,
    pub cortisol: f32,
    pub insulin: f32,
    pub metabolic_activator: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Metabolism {
    pub glucose: f32,
    pub atp_reserves: f32,
    pub lactate_level: f32,
    pub efficiency: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Immunology {
    pub leukocyte_activity: f32,
    pub antibody_vault: HashMap<String, f32>,
    pub efficiency: f32,
    pub antigen_load: f32,
    pub protection_factor: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Microbiome {
    pub flora_diversity: f32,
    pub symbiotic_ratio: f32,
    pub endotoxin_level: f32,
    pub fermentation_rate: f32,
    pub neuroactive_metabolites: NeuroactiveMetabolites,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NeuroactiveMetabolites {
    pub irritability: f32,
    pub calmness: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Skeleton {
    pub stress_level: f32,
    pub fractures: Vec<String>,
    pub integrity: f32,
    pub calcium_reserves: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Anatomy {
    pub epithelial: TissueState,
    pub connective: ConnectiveState,
    pub muscular: MuscularState,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct TissueState {
    pub health: f32,
    pub barrier_leak: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ConnectiveState {
    pub health: f32,
    pub elasticity: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MuscularState {
    pub health: f32,
    pub peak_power: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Epigenetics {
    pub methylation: HashMap<String, f32>,
    pub expression_bias: f32,
    pub generation_count: u32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Germline {
    pub gamete_health: f32,
    pub mutagenic_pressure: f32,
    pub genetic_stability: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Chrono {
    pub internal_hour: f32,
    pub melatonin_level: f32,
    pub cycle_type: String,
    pub alertness: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Environment {
    pub toxins: f32,
    pub oxygen: f32,
    pub ph: f32,
    pub weather: String,
}

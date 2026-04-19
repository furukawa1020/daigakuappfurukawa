use serde::{Deserialize, Serialize};
use std::io::{self, BufRead};
use daigakuos_core::state::BioState;
use daigakuos_core::BioKernel;

#[derive(Serialize, Deserialize)]
struct SimulationRequest {
    state: BioState,
    dt_hours: f32,
    velocity: f32,
}

#[derive(Serialize, Deserialize)]
struct SimulationResponse {
    state: BioState,
    message: String,
}

fn main() -> anyhow::Result<()> {
    let stdin = io::stdin();
    let mut lines = stdin.lock().lines();

    if let Some(Ok(line)) = lines.next() {
        let request: SimulationRequest = serde_json::from_str(&line)?;
        
        let mut state = request.state;
        BioKernel::tick(&mut state, request.dt_hours, request.velocity);
        
        let response = SimulationResponse {
            state,
            message: "Simulation tick completed successfully by Rust Bio-Kernel 🦀".to_string(),
        };
        
        println!("{}", serde_json::to_string(&response)?);
    }

    Ok(())
}
